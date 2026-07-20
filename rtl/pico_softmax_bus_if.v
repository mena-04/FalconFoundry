`timescale 1ns / 1ps

`include "softmax_params.vh"

module pico_softmax_bus_if (
    input  wire clk,
    input  wire rst_n,

    input  wire wr_en,
    input  wire rd_en,

    inout  wire [`OUT_BITS-1:0] data_bus,

    output reg input_valid,
    output reg [`INDEX_BITS-1:0] input_index,
    output reg signed [`IN_BITS-1:0] input_data,

    output reg [`INDEX_BITS-1:0] output_index,
    input  wire [`OUT_BITS-1:0] output_data,

    output reg output_read_pulse
);

    reg [`OUT_BITS-1:0] data_out;
    reg data_oe;

    assign data_bus = data_oe ? data_out : {`OUT_BITS{1'bz}};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_valid       <= 1'b0;
            input_index       <= {`INDEX_BITS{1'b0}};
            input_data        <= {`IN_BITS{1'b0}};

            output_index      <= {`INDEX_BITS{1'b0}};
            output_read_pulse <= 1'b0;

            data_out          <= {`OUT_BITS{1'b0}};
            data_oe           <= 1'b0;
        end else begin
            input_valid       <= 1'b0;
            output_read_pulse <= 1'b0;
            data_oe           <= 1'b0;

            // Host writes one input byte into chip
            if (wr_en && !rd_en) begin
                input_valid <= 1'b1;
                input_data  <= data_bus[`IN_BITS-1:0];

                if (input_index == (`VECTOR_LEN-1))
                    input_index <= {`INDEX_BITS{1'b0}};
                else
                    input_index <= input_index + 1'b1;
            end

            // Host reads one output byte from chip
            else if (rd_en && !wr_en) begin
                data_oe           <= 1'b1;
                data_out          <= output_data;
                output_read_pulse <= 1'b1;

                if (output_index == (`VECTOR_LEN-1))
                    output_index <= {`INDEX_BITS{1'b0}};
                else
                    output_index <= output_index + 1'b1;
            end
        end
    end

endmodule
