`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2026 06:17:17 PM
// Design Name: 
// Module Name: exp2_shift_unit
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
module exp2_shift_unit #(
    parameter EXP_WIDTH = 15
)(
    input  wire [EXP_WIDTH-1:0] exp_frac_q,
    input  wire [3:0]           integer_part,

    output wire [EXP_WIDTH-1:0] exp_q
);

    assign exp_q = exp_frac_q >> integer_part;

endmodule