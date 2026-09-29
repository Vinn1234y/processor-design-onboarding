module alu (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [2:0] op,
    output logic [7:0] result
);

    always_comb begin
        case (op)
            3'd0: result = a + b;
            3'd1: result = a - b;
            3'd2: result = a & b;
            3'd3: result = a | b;
            3'd4: result = a ^ b;
            default: result = '0;
        endcase
    end

endmodule
