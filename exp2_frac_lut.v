module exp2_frac_lut #(
    parameter EXP_WIDTH = 15
)(
    input  wire [3:0] frac_addr,
    output reg  [EXP_WIDTH-1:0] exp_frac_q
);

    always @* begin
        case (frac_addr)
            4'd0  : exp_frac_q = 15'd16384;
            4'd1  : exp_frac_q = 15'd15690;
            4'd2  : exp_frac_q = 15'd15025;
            4'd3  : exp_frac_q = 15'd14388;
            4'd4  : exp_frac_q = 15'd13777;
            4'd5  : exp_frac_q = 15'd13192;
            4'd6  : exp_frac_q = 15'd12632;
            4'd7  : exp_frac_q = 15'd12095;
            4'd8  : exp_frac_q = 15'd11585;
            4'd9  : exp_frac_q = 15'd11096;
            4'd10 : exp_frac_q = 15'd10628;
            4'd11 : exp_frac_q = 15'd10180;
            4'd12 : exp_frac_q = 15'd9752;
            4'd13 : exp_frac_q = 15'd9343;
            4'd14 : exp_frac_q = 15'd8952;
            4'd15 : exp_frac_q = 15'd8579;
            default: exp_frac_q = 15'd16384;
        endcase
    end

endmodule