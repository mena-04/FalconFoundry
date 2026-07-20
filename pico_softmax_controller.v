`timescale 1ns / 1ps

`include "softmax_params.vh"

module pico_softmax_controller (
    input  wire clk,
    input  wire rst_n,

    input  wire start,

    input  wire input_valid,
    input  wire max_done,
    input  wire div_done,
    input  wire output_read_pulse,

    output reg busy,
    output reg done,

    output reg input_write_en,
    output reg max_start,

    output reg exp_clear,
    output reg exp_write_en,

    output reg den_clear,
    output reg den_add_en,

    output reg div_start,
    output reg output_write_en,

    output wire [`INDEX_BITS-1:0] work_index
);

    localparam S_IDLE           = 4'd0;
    localparam S_LOAD_INPUTS    = 4'd1;
    localparam S_FIND_MAX_START = 4'd2;
    localparam S_FIND_MAX_WAIT  = 4'd3;
    localparam S_EXP_CLEAR      = 4'd4;
    localparam S_EXP_ACCUM      = 4'd5;
    localparam S_DIV_PREP       = 4'd6;
    localparam S_DIV_START      = 4'd7;
    localparam S_DIV_RUN        = 4'd8;
    localparam S_STORE_OUTPUT   = 4'd9;
    localparam S_DONE           = 4'd10;
    localparam S_OUTPUT_READ    = 4'd11;

    reg [3:0] state;
    reg [3:0] next_state;

    reg [`INDEX_BITS-1:0] load_count;
    reg [`INDEX_BITS-1:0] read_count;

    wire index_clear;
    wire index_enable;
    wire index_wrap;
    wire index_last;
    wire index_done_pulse;

    index_counter #(
        .WIDTH(`INDEX_BITS),
        .LAST_VALUE(`VECTOR_LEN-1)
    ) index_counter_inst (
        .clk(clk),
        .rst_n(rst_n),

        .clear(index_clear),
        .enable(index_enable),
        .wrap(index_wrap),

        .count(work_index),
        .last(index_last),
        .done_pulse(index_done_pulse)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            load_count <= {`INDEX_BITS{1'b0}};
            read_count <= {`INDEX_BITS{1'b0}};
        end else begin
            state <= next_state;

            if (state == S_IDLE) begin
                load_count <= {`INDEX_BITS{1'b0}};
                read_count <= {`INDEX_BITS{1'b0}};
            end

            if (state == S_LOAD_INPUTS && input_valid) begin
                if (load_count == (`VECTOR_LEN-1))
                    load_count <= {`INDEX_BITS{1'b0}};
                else
                    load_count <= load_count + 1'b1;
            end

            if ((state == S_DONE || state == S_OUTPUT_READ) && output_read_pulse) begin
                if (read_count == (`VECTOR_LEN-1))
                    read_count <= {`INDEX_BITS{1'b0}};
                else
                    read_count <= read_count + 1'b1;
            end
        end
    end

    always @(*) begin
        next_state = state;

        case (state)
            S_IDLE: begin
                if (start)
                    next_state = S_LOAD_INPUTS;
            end

            S_LOAD_INPUTS: begin
                if (input_valid && load_count == (`VECTOR_LEN-1))
                    next_state = S_FIND_MAX_START;
            end

            S_FIND_MAX_START: begin
                next_state = S_FIND_MAX_WAIT;
            end

            S_FIND_MAX_WAIT: begin
                if (max_done)
                    next_state = S_EXP_CLEAR;
            end

            S_EXP_CLEAR: begin
                next_state = S_EXP_ACCUM;
            end

            S_EXP_ACCUM: begin
                if (index_last)
                    next_state = S_DIV_PREP;
            end

            S_DIV_PREP: begin
                next_state = S_DIV_START;
            end

            S_DIV_START: begin
                next_state = S_DIV_RUN;
            end

            S_DIV_RUN: begin
                if (div_done)
                    next_state = S_STORE_OUTPUT;
            end

            S_STORE_OUTPUT: begin
                if (index_last)
                    next_state = S_DONE;
                else
                    next_state = S_DIV_PREP;
            end

            S_DONE: begin
                if (output_read_pulse) begin
                    if (read_count == (`VECTOR_LEN-1))
                        next_state = S_IDLE;
                    else
                        next_state = S_OUTPUT_READ;
                end
            end

            S_OUTPUT_READ: begin
                if (output_read_pulse && read_count == (`VECTOR_LEN-1))
                    next_state = S_IDLE;
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    assign index_wrap = 1'b1;

    assign index_clear =
        (state == S_IDLE) ||
        (state == S_EXP_CLEAR);

    assign index_enable =
        (state == S_EXP_ACCUM) ||
        (state == S_STORE_OUTPUT);

    always @(*) begin
        busy            = 1'b0;
        done            = 1'b0;

        input_write_en  = 1'b0;
        max_start       = 1'b0;

        exp_clear       = 1'b0;
        exp_write_en    = 1'b0;

        den_clear       = 1'b0;
        den_add_en      = 1'b0;

        div_start       = 1'b0;
        output_write_en = 1'b0;

        case (state)
            S_LOAD_INPUTS: begin
                busy = 1'b1;
                input_write_en = input_valid;
            end

            S_FIND_MAX_START: begin
                busy = 1'b1;
                max_start = 1'b1;
            end

            S_FIND_MAX_WAIT: begin
                busy = 1'b1;
            end

            S_EXP_CLEAR: begin
                busy = 1'b1;
                exp_clear = 1'b1;
                den_clear = 1'b1;
            end

            S_EXP_ACCUM: begin
                busy = 1'b1;
                exp_write_en = 1'b1;
                den_add_en = 1'b1;
            end

            S_DIV_PREP: begin
                busy = 1'b1;
            end

            S_DIV_START: begin
                busy = 1'b1;
                div_start = 1'b1;
            end

            S_DIV_RUN: begin
                busy = 1'b1;
            end

            S_STORE_OUTPUT: begin
                busy = 1'b1;
                output_write_en = 1'b1;
            end

            S_DONE: begin
                busy = 1'b0;
                done = 1'b1;
            end

            S_OUTPUT_READ: begin
                busy = 1'b0;
                done = 1'b1;
            end

            default: begin
                busy = 1'b0;
                done = 1'b0;
            end
        endcase
    end

endmodule