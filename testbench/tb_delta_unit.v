`timescale 1ns/1ps

module tb_delta_unit;

    reg signed [7:0] max_q;
    reg signed [7:0] x_q;
    wire [7:0] delta_q;

    delta_unit dut (
        .max_q(max_q),
        .x_q(x_q),
        .delta_q(delta_q)
    );

    task check;
        input signed [7:0] max_val;
        input signed [7:0] x_val;
        input [7:0] expected;
    begin
        max_q = max_val;
        x_q = x_val;
        #10;

        if (delta_q == expected)
            $display("PASS: max=%0d x=%0d delta=%0d", max_q, x_q, delta_q);
        else
            $display("FAIL: max=%0d x=%0d delta=%0d expected=%0d",
                     max_q, x_q, delta_q, expected);
    end
    endtask

    initial begin
        check(6, 2, 4);
        check(6, 6, 0);
        check(6, 1, 5);
        check(-1, -4, 3);
        check(7, -2, 9);

        $display("tb_delta_unit completed.");
        $stop;
    end

endmodule