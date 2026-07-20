`timescale 1ns/1ps

module tb_exp2_hybrid_unit;

    reg [7:0] delta_q;
    wire [7:0] exp_q;

    exp2_hybrid_unit dut (
        .delta_q(delta_q),
        .exp_q(exp_q)
    );

    task check;
        input [7:0] delta;
        input [7:0] expected;
    begin
        delta_q = delta;
        #10;

        if (exp_q == expected)
            $display("PASS: delta=%0d exp=%0d", delta_q, exp_q);
        else
            $display("FAIL: delta=%0d exp=%0d expected=%0d",
                     delta_q, exp_q, expected);
    end
    endtask

    initial begin
        /*
            Assumption:
            delta_q is Q3.4.
            delta = 0.0  -> 0
            delta = 1.0  -> 16
            delta = 2.0  -> 32
            delta = 3.0  -> 48
            exp output is Q0.8.
        */

        check(8'd0,  8'd255);  // 2^0
        check(8'd16, 8'd127);  // 2^-1
        check(8'd32, 8'd63);   // 2^-2
        check(8'd48, 8'd31);   // 2^-3
        check(8'd64, 8'd15);   // 2^-4

        $display("tb_exp2_hybrid_unit completed.");
        $stop;
    end

endmodule