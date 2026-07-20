`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/30/2026 02:13:35 AM
// Design Name: 
// Module Name: input_vector_buffer
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

`include "softmax_params.vh"

module input_vector_buffer (
    input  wire clk,
    input  wire rst_n,

    input  wire write_en,
    input  wire [`INDEX_BITS-1:0] write_addr,
    input  wire signed [`IN_BITS-1:0] write_data,

    input  wire [`INDEX_BITS-1:0] read_addr,
    output reg signed [`IN_BITS-1:0] read_data
);

    reg signed [`IN_BITS-1:0] x_mem [0:`VECTOR_LEN-1];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < `VECTOR_LEN; i = i + 1) begin
                x_mem[i] <= 0;
            end
        end else begin
            if (write_en) begin
                x_mem[write_addr] <= write_data;
            end
        end
    end

    always @(*) begin
        read_data = x_mem[read_addr];
    end

endmodule
