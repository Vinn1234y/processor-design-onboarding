module sequence_detector_tb;

    logic clk;
    logic reset;
    logic x;
    logic detect;

    sequence_detector dut (
        .clk(clk),
        .reset(reset),
        .x(x),
        .detect(detect)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task send_bit(
        input logic bit_value,
        input logic expected_detect
    );
        begin
            x = bit_value;

            @(posedge clk);
            #1;

            if (detect !== expected_detect)
                $fatal(1, 
                    "Detection failed: x=%0b expected=%0b got=%0b",
                    bit_value,
                    expected_detect,
                    detect
                );
        end
    endtask

    initial begin
        reset = 1;
        x = 0;

        @(posedge clk);
        #1;

        reset = 0;

        // Detect 1011
        send_bit(1, 0);
        send_bit(0, 0);
        send_bit(1, 0);
        send_bit(1, 1);

        // No detection
        send_bit(0, 0);
        send_bit(0, 0);

        // Test overlapping detections in 1011011
        reset = 1;
        @(posedge clk);
        #1;
        reset = 0;

        send_bit(1, 0);
        send_bit(0, 0);
        send_bit(1, 0);
        send_bit(1, 1);
        send_bit(0, 0);
        send_bit(1, 0);
        send_bit(1, 1);

        $display("All sequence detector tests passed!");
        $finish;
    end

endmodule
