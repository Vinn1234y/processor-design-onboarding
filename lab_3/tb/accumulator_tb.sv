`timescale 1ns/1ps

module accumulator_tb;

    logic clk;
    logic reset;
    logic enable;
    logic [7:0] data_in;
    logic [7:0] sum;

    logic [7:0] expected_sum;

    accumulator #(
        .WIDTH(8)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .data_in(data_in),
        .sum(sum)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Watchdog timer
    initial begin
        #100us;
        $fatal(1, "Simulation timed out");
    end

    // Task to verify expected sum
    task check_sum(input logic [7:0] expected);
        begin
            if (sum !== expected)
                $fatal(
                    1,
                    "Expected sum=%0d, got sum=%0d",
                    expected,
                    sum
                );
        end
    endtask

    // Helper task for directed tests
    task apply_and_check(
        input logic       rst_val,
        input logic       en_val,
        input logic [7:0] din_val,
        input logic [7:0] expected
    );
        begin
            @(negedge clk);
            reset   = rst_val;
            enable  = en_val;
            data_in = din_val;

            @(posedge clk);
            #1;
            check_sum(expected);
        end
    endtask

    initial begin
        reset   = 1;
        enable  = 0;
        data_in = 8'd0;

        // --- Directed Tests ---
        // 1. Verify reset clears sum
        apply_and_check(1, 0, 8'd0,   8'd0);

        // 2. Verify one addition works (0 + 15 = 15)
        apply_and_check(0, 1, 8'd15,  8'd15);

        // 3. Verify several additions accumulate correctly
        apply_and_check(0, 1, 8'd25,  8'd40);  // 15 + 25 = 40
        apply_and_check(0, 1, 8'd60,  8'd100); // 40 + 60 = 100

        // 4. Verify enable = 0 holds the value
        apply_and_check(0, 0, 8'd50,  8'd100);
        apply_and_check(0, 0, 8'd200, 8'd100);

        // 5. Verify counting resumes when re-enabled (100 + 150 = 250)
        apply_and_check(0, 1, 8'd150, 8'd250);

        // 6. Verify 8-bit overflow wraps correctly (250 + 10 = 260 -> 4)
        apply_and_check(0, 1, 8'd10,  8'd4);

        // --- Randomized Testing with Reference Model ---
        // Reset the DUT and initialize expected_sum
        @(negedge clk);
        reset   = 1;
        enable  = 0;
        data_in = 8'd0;
        expected_sum = 8'd0;

        @(posedge clk);
        #1;
        check_sum(expected_sum);

        @(negedge clk);
        reset = 0;

        // Run 100 randomized cycles
        repeat (100) begin
            @(negedge clk);
            enable  = 1'($urandom_range(1, 0));
            data_in = 8'($urandom_range(255, 0));

            if (enable)
                expected_sum = expected_sum + data_in;

            @(posedge clk);
            #1;
            check_sum(expected_sum);
        end

        $display("All accumulator tests passed!");
        $finish;
    end

endmodule
