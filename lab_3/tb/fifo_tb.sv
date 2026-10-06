`timescale 1ns/1ps

module fifo_tb;

    localparam WIDTH = 8;
    localparam DEPTH = 4;

    logic             clk;
    logic             reset;
    logic             wr_en;
    logic [WIDTH-1:0] wr_data;
    logic             rd_en;
    logic [WIDTH-1:0] rd_data;
    logic             full;
    logic             empty;

    // Reference model variables for randomized testing
    logic [WIDTH-1:0] expected_queue[$];
    logic [WIDTH-1:0] expected_rd_data;
    logic             do_write;
    logic             do_read;

    fifo #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .full(full),
        .empty(empty)
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

    task check_flags(input logic exp_full, input logic exp_empty);
        begin
            if (full !== exp_full || empty !== exp_empty)
                $fatal(
                    1,
                    "Flag mismatch: expected full=%0b empty=%0b, got full=%0b empty=%0b",
                    exp_full, exp_empty, full, empty
                );
        end
    endtask

    task check_data(input logic [WIDTH-1:0] exp_data);
        begin
            if (rd_data !== exp_data)
                $fatal(
                    1,
                    "Data mismatch: expected rd_data=%0d, got rd_data=%0d",
                    exp_data, rd_data
                );
        end
    endtask

    task step_fifo(
        input logic             rst_val,
        input logic             w_en,
        input logic [WIDTH-1:0] w_val,
        input logic             r_en
    );
        begin
            @(negedge clk);
            reset   = rst_val;
            wr_en   = w_en;
            wr_data = w_val;
            rd_en   = r_en;
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        reset   = 1;
        wr_en   = 0;
        wr_data = '0;
        rd_en   = 0;

        // --- Directed Tests ---
        // 1. Reset produces empty = 1, full = 0, rd_data = 0
        step_fifo(1, 0, 8'd0, 0);
        check_flags(0, 1);
        check_data(8'd0);

        // 2. One write makes the FIFO non-empty
        step_fifo(0, 1, 8'd11, 0);
        check_flags(0, 0);

        // 3. Write then read returns the correct data (and returns to empty)
        step_fifo(0, 0, 8'd0, 1);
        check_flags(0, 1);
        check_data(8'd11);

        // 4. Multiple values preserve order & 5. Filling the FIFO asserts full
        step_fifo(0, 1, 8'd10, 0);
        check_flags(0, 0);
        step_fifo(0, 1, 8'd20, 0);
        check_flags(0, 0);
        step_fifo(0, 1, 8'd30, 0);
        check_flags(0, 0);
        step_fifo(0, 1, 8'd40, 0);
        check_flags(1, 0); // FIFO is now full (4 items)

        // 6. A write while full is rejected
        step_fifo(0, 1, 8'd99, 0);
        check_flags(1, 0);

        // 7. Draining the FIFO asserts empty (and verifies 99 was rejected)
        step_fifo(0, 0, 8'd0, 1);
        check_flags(0, 0);
        check_data(8'd10);

        step_fifo(0, 0, 8'd0, 1);
        check_flags(0, 0);
        check_data(8'd20);

        step_fifo(0, 0, 8'd0, 1);
        check_flags(0, 0);
        check_data(8'd30);

        step_fifo(0, 0, 8'd0, 1);
        check_flags(0, 1); // Drained to empty
        check_data(8'd40);

        // 8. A read while empty is rejected (rd_data holds 40, stays empty)
        step_fifo(0, 0, 8'd0, 1);
        check_flags(0, 1);
        check_data(8'd40);

        // 9. Pointer wraparound & 10. Simultaneous read/write
        step_fifo(0, 1, 8'd50, 0);
        check_flags(0, 0);
        step_fifo(0, 1, 8'd60, 0);
        check_flags(0, 0);

        // Simultaneous read (gets 50) and write (stores 70); count stays 2
        step_fifo(0, 1, 8'd70, 1);
        check_flags(0, 0);
        check_data(8'd50);

        // Drain remaining 60 and 70
        step_fifo(0, 0, 8'd0, 1);
        check_flags(0, 0);
        check_data(8'd60);

        step_fifo(0, 0, 8'd0, 1);
        check_flags(0, 1);
        check_data(8'd70);

        // --- Randomized Testing with Queue Reference Model ---
        expected_queue.delete();
        step_fifo(1, 0, 8'd0, 0);
        check_flags(0, 1);
        check_data(8'd0);

        @(negedge clk);
        reset = 0;

        repeat (200) begin
            @(negedge clk);
            wr_en   = 1'($urandom_range(1, 0));
            rd_en   = 1'($urandom_range(1, 0));
            wr_data = 8'($urandom_range(255, 0));

            do_write = wr_en && !full;
            do_read  = rd_en && !empty;

            if (do_write)
                expected_queue.push_back(wr_data);

            if (do_read)
                expected_rd_data = expected_queue.pop_front();

            @(posedge clk);
            #1;

            if (do_read)
                check_data(expected_rd_data);

            if (empty !== (expected_queue.size() == 0))
                $fatal(1, "Incorrect empty flag");

            if (full !== (expected_queue.size() == DEPTH))
                $fatal(1, "Incorrect full flag");
        end

        $display("All FIFO tests passed!");
        $finish;
    end

endmodule
