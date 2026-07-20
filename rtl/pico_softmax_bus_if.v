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

    assign data_bus =
        data_oe
        ? data_out
        : {`OUT_BITS{1'bz}};

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
            /*
                Default one-cycle pulse values.
            */

            input_valid       <= 1'b0;
            output_read_pulse <= 1'b0;
            data_oe           <= 1'b0;

            /*
                Increment the input address only after the previously
                captured input has been presented to the input buffer.

                At this edge, the input buffer sees:
                    input_valid = 1
                    input_data  = previous captured byte
                    input_index = current write address

                The index then advances for the next input.
            */

            if (input_valid) begin
                if (input_index == (`VECTOR_LEN - 1)) begin
                    input_index <= {`INDEX_BITS{1'b0}};
                end else begin
                    input_index <= input_index + 1'b1;
                end
            end

            /*
                Host writes one input byte into the accelerator.

                Capture the byte and assert input_valid. The current
                input_index is retained until the input buffer writes
                the captured value on the following rising edge.
            */

            if (wr_en && !rd_en) begin
                input_valid <= 1'b1;
                input_data  <= data_bus[`IN_BITS-1:0];
            end

            /*
                Host reads one output byte from the accelerator.
            */

            else if (rd_en && !wr_en) begin
                data_oe           <= 1'b1;
                data_out          <= output_data;
                output_read_pulse <= 1'b1;

                if (output_index == (`VECTOR_LEN - 1)) begin
                    output_index <= {`INDEX_BITS{1'b0}};
                end else begin
                    output_index <= output_index + 1'b1;
                end
            end
        end
    end

endmodule
