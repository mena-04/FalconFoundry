`timescale 1ns / 1ps

`include "softmax_params.vh"

module pico_softmax_top (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire wr_en,
    input  wire rd_en,

    inout  wire [`OUT_BITS-1:0] data_bus,

    output wire busy,
    output wire done
);

    wire input_valid;
    wire [`INDEX_BITS-1:0] input_index;
    wire signed [`IN_BITS-1:0] input_data;

    wire [`INDEX_BITS-1:0] output_index;
    wire [`OUT_BITS-1:0] output_data;
    wire output_read_pulse;

    wire input_write_en;

    wire [`INDEX_BITS-1:0] work_index;

    wire index_clear;
    wire index_enable;
    wire index_wrap;
    wire index_last;
    wire index_done_pulse;

    wire [`INDEX_BITS-1:0] x_read_addr;
    wire signed [`IN_BITS-1:0] x_read_data;

    wire max_start;
    wire max_busy;
    wire max_done;
    wire [`INDEX_BITS-1:0] max_read_addr;
    wire signed [`IN_BITS-1:0] max_q;

    wire signed [`IN_BITS:0] delta_q;
    wire [`IN_BITS:0] magnitude_q;

    wire exp_clear;
    wire exp_write_en;
    wire [`EXP_BITS-1:0] exp_q;
    wire [`EXP_BITS-1:0] exp_read_data;

    wire den_clear;
    wire den_add_en;
    wire [`DEN_BITS-1:0] den_q;

    wire div_start;
    wire div_busy;
    wire div_done;
    wire [`OUT_BITS-1:0] div_quotient;

    wire output_write_en;
    wire output_clear;

    assign x_read_addr = max_busy ? max_read_addr : work_index;
    assign output_clear = exp_clear;

    pico_softmax_bus_if bus_if_inst (
        .clk(clk),
        .rst_n(rst_n),

        .wr_en(wr_en),
        .rd_en(rd_en),

        .data_bus(data_bus),

        .input_valid(input_valid),
        .input_index(input_index),
        .input_data(input_data),

        .output_index(output_index),
        .output_data(output_data),

        .output_read_pulse(output_read_pulse)
    );


		pico_softmax_controller controller_inst (
			 .clk(clk),
			 .rst_n(rst_n),

			 .start(start),

			 .input_valid(input_valid),
			 .max_done(max_done),
			 .div_done(div_done),
			 .output_read_pulse(output_read_pulse),

			 .busy(busy),
			 .done(done),

			 .input_write_en(input_write_en),
			 .max_start(max_start),

			 .exp_clear(exp_clear),
			 .exp_write_en(exp_write_en),

			 .den_clear(den_clear),
			 .den_add_en(den_add_en),

			 .div_start(div_start),
			 .output_write_en(output_write_en),

			 .work_index(work_index)
		);
			

    input_vector_buffer input_buffer_inst (
        .clk(clk),
        .rst_n(rst_n),

        .write_en(input_write_en),
        .write_addr(input_index),
        .write_data(input_data),

        .read_addr(x_read_addr),
        .read_data(x_read_data)
    );

    max_finder max_finder_inst (
        .clk(clk),
        .rst_n(rst_n),

        .start(max_start),
        .x_in(x_read_data),

        .read_addr(max_read_addr),
        .max_q(max_q),
        .busy(max_busy),
        .done(max_done)
    );

    delta_unit delta_unit_inst (
        .x_q(x_read_data),
        .max_q(max_q),

        .delta_q(delta_q),
        .magnitude(magnitude_q)
    );

    exp2_hybrid_unit exp2_hybrid_inst (
        .magnitude(magnitude_q),
        .exp_q(exp_q)
    );

    exp_buffer exp_buffer_inst (
        .clk(clk),
        .rst_n(rst_n),

        .clear(exp_clear),

        .write_en(exp_write_en),
        .write_addr(work_index),
        .write_data(exp_q),

        .read_addr(work_index),
        .read_data(exp_read_data)
    );

    denominator_accumulator den_acc_inst (
        .clk(clk),
        .rst_n(rst_n),

        .clear(den_clear),
        .add_en(den_add_en),
        .exp_q(exp_q),

        .den_q(den_q)
    );

    serial_fractional_divider divider_inst (
        .clk(clk),
        .rst_n(rst_n),

        .start(div_start),
        .numerator(exp_read_data),
        .denominator(den_q),

        .quotient(div_quotient),
        .busy(div_busy),
        .done(div_done)
    );

    output_buffer output_buffer_inst (
        .clk(clk),
        .rst_n(rst_n),

        .clear(output_clear),

        .write_en(output_write_en),
        .write_addr(work_index),
        .write_data(div_quotient),

        .read_addr(output_index),
        .read_data(output_data)
    );

endmodule
