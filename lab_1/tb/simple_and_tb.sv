module simple_and_tb;

    logic a;
    logic b;
    logic y;

    simple_and dut (
        .a(a),
        .b(b),
        .y(y)
    );

    initial begin
        a = 0; b = 0; #1;
        if (y !== 0) $fatal("00 failed");

        a = 0; b = 1; #1;
        if (y !== 0) $fatal("01 failed");

        a = 1; b = 0; #1;
        if (y !== 0) $fatal("10 failed");

        a = 1; b = 1; #1;
        if (y !== 1) $fatal("11 failed");

        $display("All tests passed!");
        $finish;
    end

endmodule
