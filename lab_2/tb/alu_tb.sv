module alu_tb;

    logic [7:0] a;
    logic [7:0] b;
    logic [2:0] op;
    logic [7:0] result;

    alu dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result)
    );

    initial begin
        a = 8'd10;
        b = 8'd3;

        op = 3'd0;
        #1;
        if (result !== 8'd13)
            $fatal(1, "ADD failed");

        op = 3'd1;
        #1;
        if (result !== 8'd7)
            $fatal(1, "SUB failed");

        op = 3'd2;
        #1;
        if (result !== 8'd2)
            $fatal(1, "AND failed");

        op = 3'd3;
        #1;
        if (result !== 8'd11)
            $fatal(1, "OR failed");

        op = 3'd4;
        #1;
        if (result !== 8'd9)
            $fatal(1, "XOR failed");

        op = 3'd7; // Unsupported opcode
        #1;
        if (result !== 8'd0)
            $fatal(1, "Unsupported opcode failed");

        $display("All ALU tests passed!");
        $finish;
    end

endmodule
