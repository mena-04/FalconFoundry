`timescale 1ns/1ps

module tb_exp2_frac_lut;

    reg [3:0] frac_q;
    wire [7:0] lut_out;

    exp2_frac_lut dut (
        .frac_q(frac_q),
        .lut_out(lut_out)
    );

    task check;
        input [3:0] frac;
        input [7:0] expected;
    begin
        frac_q = frac;
        #10;

        if (lut_out == expected)
            $display("PASS: frac=%0d lut_out=%0d", frac_q, lut_out);
        else
            $display("FAIL: frac=%0d lut_out=%0d expected=%0d",
                     frac_q, lut_out, expected);
    end
    endtask

    initial begin
        /*
            Update expected values if your Python LUT is different.
            These are typical Q0.8 approximations for 2^(-frac/16).
        */

        check(4'd0, 8'd255);
        check(4'd1, 8'd245);
        check(4'd2, 8'd234);
        check(4'd3, 8'd224);
        check(4'd4, 8'd215);
        check(4'd5, 8'd205);
        check(4'd6, 8'd197);
        check(4'd7, 8'd188);
        check(4'd8, 8'd180);
        check(4'd9, 8'd172);
        check(4'd10, 8'd165);
        check(4'd11, 8'd158);
        check(4'd12, 8'd151);
        check(4'd13, 8'd145);
        check(4'd14, 8'd139);
        check(4'd15, 8'd133);

        $display("tb_exp2_frac_lut completed.");
        $stop;
    end

endmodule