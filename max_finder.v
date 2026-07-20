`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/30/2026 02:14:27 AM
// Design Name: 
// Module Name: max_finder
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

module max_finder (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire signed [`IN_BITS-1:0] x_in,

    output reg [`INDEX_BITS-1:0] read_addr,
    output reg signed [`IN_BITS-1:0] max_q,
    output reg busy,
    output reg done
);

    reg [`INDEX_BITS-1:0] index;
    reg running;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            index     <= 0;
            read_addr <= 0;
            max_q     <= 0;
            busy      <= 0;
            done      <= 0;
            running   <= 0;
        end else begin
            done <= 0;

            if (start && !running) begin
                index     <= 0;
                read_addr <= 0;
                max_q     <= 0;
                busy      <= 1;
                running   <= 1;
            end else if (running) begin

                if (index == 0) begin
                    max_q <= x_in;
                end else begin
                    if (x_in > max_q) begin
                        max_q <= x_in;
                    end
                end

                if (index == (`VECTOR_LEN-1)) begin
                    busy    <= 0;
                    done    <= 1;
                    running <= 0;
                end else begin
                    index     <= index + 1'b1;
                    read_addr <= index + 1'b1;
                end
            end
        end
    end

endmodule
