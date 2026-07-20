`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2026 06:15:57 PM
// Design Name: 
// Module Name: exp_buffer
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

module exp_buffer #(
    parameter VECTOR_LEN  = 8,
    parameter INDEX_WIDTH = 3,
    parameter EXP_WIDTH   = 15
)(
    input  wire                   clk,
    input  wire                   rst_n,

    input  wire                   clear,

    input  wire                   write_en,
    input  wire [INDEX_WIDTH-1:0] write_addr,
    input  wire [EXP_WIDTH-1:0]   write_data,

    input  wire [INDEX_WIDTH-1:0] read_addr,
    output reg  [EXP_WIDTH-1:0]   read_data
);

    reg [EXP_WIDTH-1:0] mem [0:VECTOR_LEN-1];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < VECTOR_LEN; i = i + 1) begin
                mem[i] <= {EXP_WIDTH{1'b0}};
            end
        end else if (clear) begin
            for (i = 0; i < VECTOR_LEN; i = i + 1) begin
                mem[i] <= {EXP_WIDTH{1'b0}};
            end
        end else if (write_en) begin
            mem[write_addr] <= write_data;
        end
    end

    always @* begin
        read_data = mem[read_addr];
    end

endmodule
