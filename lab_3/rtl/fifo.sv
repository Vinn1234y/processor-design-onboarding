`timescale 1ns/1ps

module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 4
) (
    input  logic             clk,
    input  logic             reset,

    input  logic             wr_en,
    input  logic [WIDTH-1:0] wr_data,

    input  logic             rd_en,
    output logic [WIDTH-1:0] rd_data,

    output logic             full,
    output logic             empty
);

    localparam PTR_WIDTH   = $clog2(DEPTH);
    localparam COUNT_WIDTH = $clog2(DEPTH + 1);

    logic [WIDTH-1:0]       mem [0:DEPTH-1];
    logic [PTR_WIDTH-1:0]   wr_ptr;
    logic [PTR_WIDTH-1:0]   rd_ptr;
    logic [COUNT_WIDTH-1:0] count;

    logic do_write;
    logic do_read;

    always_comb begin
        empty    = (count == '0);
        full     = (count == COUNT_WIDTH'(DEPTH));
        do_write = wr_en && !full;
        do_read  = rd_en && !empty;
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            wr_ptr  <= '0;
            rd_ptr  <= '0;
            count   <= '0;
            rd_data <= '0;
        end else begin
            if (do_write) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr      <= wr_ptr + 1'b1;
            end

            if (do_read) begin
                rd_data <= mem[rd_ptr];
                rd_ptr  <= rd_ptr + 1'b1;
            end

            case ({do_write, do_read})
                2'b10:   count <= count + 1'b1;
                2'b01:   count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
