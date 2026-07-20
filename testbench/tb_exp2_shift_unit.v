`timescale 1ns/1ps

module tb_exp2_shift_unit;

    reg [7:0] lut_in;
    reg [3:0] int_part;
    wire [7:0] exp_out;

    exp2_shift_unit dut (
        .lut_in(lut_in),
        .int_part(int_part),
        .exp_out(exp_out)
    );

    task check;
        input [7:0] lut_val;
        input [3:0] shift_val;
        input [7:0] expected;
    begin
        lut_in = lut_val;
        int_part = shift_val;
        #10;

        if (exp_out == expected)
            $display("PASS: lut=%0d shift=%0d exp=%0d",
                     lut_in, int_part, exp_out);
        else
            $display("FAIL: lut=%0d shift=%0d exp=%0d expected=%0d",
                     lut_in, int_part, exp_out, expected);
    end
    endtask

    initial begin
        check(8'd255, 4'd0, 8'd255);
        check(8'd255, 4'd1, 8'd127);
        check(8'd255, 4'd2, 8'd63);
        check(8'd255, 4'd3, 8'd31);
        check(8'd128, 4'd1, 8'd64);
        check(8'd64,  4'd2, 8'd16);

        $display("tb_exp2_shift_unit completed.");
        $stop;
    end

endmodule