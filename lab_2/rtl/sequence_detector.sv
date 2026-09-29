module sequence_detector (
    input  logic clk,
    input  logic reset,
    input  logic x,
    output logic detect
);

    typedef enum logic [2:0] {
        S0, // matched nothing
        S1, // matched "1"
        S2, // matched "10"
        S3, // matched "101"
        S4  // matched "1011"
    } state_t;

    state_t state, next_state;

    // State register (Sequential logic)
    always_ff @(posedge clk) begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

    // Next-state and output logic (Combinational logic)
    always_comb begin
        // Default assignments to prevent latches
        next_state = state;
        detect = 1'b0;

        case (state)
            S0: begin
                if (x) next_state = S1;
                else   next_state = S0;
            end
            S1: begin
                if (x) next_state = S1;
                else   next_state = S2;
            end
            S2: begin
                if (x) next_state = S3;
                else   next_state = S0;
            end
            S3: begin
                if (x) next_state = S4;
                else   next_state = S2; // "1010" ends in "10", go to S2
            end
            S4: begin
                detect = 1'b1;
                if (x) next_state = S1; // "10111" ends in "1", go to S1
                else   next_state = S2; // "10110" ends in "10", go to S2 (overlapping support)
            end
            default: begin
                next_state = S0;
            end
        endcase
    end

endmodule
