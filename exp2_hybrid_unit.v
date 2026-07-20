module exp2_hybrid_unit #(
    parameter MAG_WIDTH = 9,
    parameter EXP_WIDTH = 15
)(
    input  wire [MAG_WIDTH-1:0] magnitude,
    output wire [EXP_WIDTH-1:0] exp_q
);

    wire [3:0] integer_part;
    wire [3:0] fractional_part;
    wire [EXP_WIDTH-1:0] exp_frac_q;

    assign integer_part    = magnitude[7:4];
    assign fractional_part = magnitude[3:0];

    exp2_frac_lut #(
        .EXP_WIDTH(EXP_WIDTH)
    ) u_exp2_frac_lut (
        .frac_addr(fractional_part),
        .exp_frac_q(exp_frac_q)
    );

    exp2_shift_unit #(
        .EXP_WIDTH(EXP_WIDTH)
    ) u_exp2_shift_unit (
        .exp_frac_q(exp_frac_q),
        .integer_part(integer_part),
        .exp_q(exp_q)
    );

endmodule