module denominator_accumulator #(
    parameter EXP_WIDTH = 15,
    parameter DEN_WIDTH = 18
)(
    input  wire                   clk,
    input  wire                   rst_n,

    input  wire                   clear,
    input  wire                   add_en,

    input  wire [EXP_WIDTH-1:0]   exp_q,
    output reg  [DEN_WIDTH-1:0]   den_q
);

    /*
        exp_q is 15 bits.
        den_q is 18 bits.

        Before adding, zero-extend exp_q to denominator width.
    */

    wire [DEN_WIDTH-1:0] exp_ext;

    assign exp_ext = {{(DEN_WIDTH-EXP_WIDTH){1'b0}}, exp_q};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            den_q <= {DEN_WIDTH{1'b0}};
        end else if (clear) begin
            den_q <= {DEN_WIDTH{1'b0}};
        end else if (add_en) begin
            den_q <= den_q + exp_ext;
        end
    end

endmodule
