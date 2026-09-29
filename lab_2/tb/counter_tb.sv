module counter_tb;

    logic clk;
    logic reset;
    logic enable;
    logic [3:0] count;

    counter #(
        .WIDTH(4)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .count(count)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1;
        enable = 0;

        @(posedge clk);
        #1;

        if (count !== 4'd0)
            $fatal(1, "Reset failed");

        reset = 0;
        enable = 1;

        @(posedge clk);
        #1;

        if (count !== 4'd1)
            $fatal(1, "First increment failed");

        @(posedge clk);
        #1;

        if (count !== 4'd2)
            $fatal(1, "Second increment failed");

        enable = 0;

        @(posedge clk);
        #1;

        if (count !== 4'd2)
            $fatal(1, "Counter did not hold");

        enable = 1;

        @(posedge clk);
        #1;

        if (count !== 4'd3)
            $fatal(1, "Counter did not resume");

        $display("All counter tests passed!");
        $finish;
    end

endmodule
