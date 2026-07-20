`timescale 1ns/1ps

module tb_exp2_shift_unit;

    localparam EXP_WIDTH = 15;

    reg  [EXP_WIDTH-1:0] exp_frac_q;
    reg  [3:0]           integer_part;
    wire [EXP_WIDTH-1:0] exp_q;

    integer pass_count;
    integer fail_count;

    exp2_shift_unit #(
        .EXP_WIDTH(EXP_WIDTH)
    ) dut (
        .exp_frac_q (exp_frac_q),
        .integer_part(integer_part),
        .exp_q      (exp_q)
    );

    task automatic check_shift;
        input [EXP_WIDTH-1:0] frac_value;
        input [3:0] shift_value;
        input [EXP_WIDTH-1:0] expected;
        begin
            exp_frac_q  = frac_value;
            integer_part = shift_value;
            #10;

            if (exp_q === expected) begin
                $display("PASS: exp_frac_q=%0d shift=%0d exp_q=%0d",
                         exp_frac_q, integer_part, exp_q);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL: exp_frac_q=%0d shift=%0d exp_q=%0d expected=%0d",
                         exp_frac_q, integer_part, exp_q, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count   = 0;
        fail_count   = 0;
        exp_frac_q   = 0;
        integer_part = 0;

        check_shift(15'd16384, 4'd0, 15'd16384);
        check_shift(15'd16384, 4'd1, 15'd8192);
        check_shift(15'd16384, 4'd2, 15'd4096);
        check_shift(15'd16384, 4'd3, 15'd2048);
        check_shift(15'd13777, 4'd1, 15'd6888);
        check_shift(15'd11585, 4'd2, 15'd2896);
        check_shift(15'd8579,  4'd4, 15'd536);
        check_shift(15'd16384, 4'd14, 15'd1);
        check_shift(15'd16384, 4'd15, 15'd0);

        $display("--------------------------------------------");
        $display("tb_exp2_shift_unit completed: PASS=%0d FAIL=%0d",
                 pass_count, fail_count);
        $display("--------------------------------------------");

        if (fail_count == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");

        $finish;
    end

endmodule
