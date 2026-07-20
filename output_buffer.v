`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2026 06:22:48 PM
// Design Name: 
// Module Name: output_buffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module output_buffer #(
    parameter VECTOR_LEN  = 8,
    parameter INDEX_WIDTH = 3,
    parameter OUT_BITS    = 8
)(
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire                    clear,

    input  wire                    write_en,
    input  wire [INDEX_WIDTH-1:0]  write_addr,
    input  wire [OUT_BITS-1:0]     write_data,

    input  wire [INDEX_WIDTH-1:0]  read_addr,
    output reg  [OUT_BITS-1:0]     read_data
);

    /*
        Stores the 8 output probabilities.

        Each probability is an unsigned Q0.8 byte:

            y_real ~= y_q / 256

        Example:
            y_q = 8'd64  means approximately 0.25
            y_q = 8'd128 means approximately 0.5
            y_q = 8'd255 means approximately 0.99609375
    */

    reg [OUT_BITS-1:0] mem [0:VECTOR_LEN-1];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < VECTOR_LEN; i = i + 1) begin
                mem[i] <= {OUT_BITS{1'b0}};
            end
        end else if (clear) begin
            for (i = 0; i < VECTOR_LEN; i = i + 1) begin
                mem[i] <= {OUT_BITS{1'b0}};
            end
        end else if (write_en) begin
            mem[write_addr] <= write_data;
        end
    end

    always @* begin
        read_data = mem[read_addr];
    end

endmodule
