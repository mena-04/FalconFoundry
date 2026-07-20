`timescale 1ns/1ps

module tb_delta_unit;

    // Q3.4 signed inputs
    reg  signed [7:0] max_q;
    reg  signed [7:0] x_q;

    // delta = max_q - x_q, always non-negative in normal Softmax use
    wire        [7:0] delta_q;

    integer pass_count;
    integer fail_count;

    // DUT
    delta_unit dut (
        .max_q   (max_q),
        .x_q     (x_q),
        .delta_q (delta_q)
    );

    task automatic check_delta;
        input signed [7:0] max_val;
        input signed [7:0] x_val;
        input        [7:0] expected;
        begin
            max_q = max_val;
            x_q   = x_val;
            #10;

            if (delta_q === expected) begin
                $display("PASS: max=%0d x=%0d delta=%0d expected=%0d",
                         $signed(max_q), $signed(x_q), delta_q, expected);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL: max=%0d x=%0d delta=%0d expected=%0d",
                         $signed(max_q), $signed(x_q), delta_q, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        max_q = 0;
        x_q   = 0;

        // Integer-value checks
        check_delta( 8'sd6,  8'sd2, 8'd4);
        check_delta( 8'sd6,  8'sd6, 8'd0);
        check_delta( 8'sd6,  8'sd1, 8'd5);
        check_delta(-8'sd1, -8'sd4, 8'd3);
        check_delta( 8'sd7, -8'sd2, 8'd9);

        // Q3.4 raw-code checks:
        // 2.0 = 32, 1.0 = 16, so delta = 16 (1.0)
        check_delta(8'sd32, 8'sd16, 8'd16);

        // 1.5 = 24, -0.5 = -8, so delta = 32 (2.0)
        check_delta(8'sd24, -8'sd8, 8'd32);

        $display("--------------------------------------------");
        $display("tb_delta_unit completed: PASS=%0d FAIL=%0d",
                 pass_count, fail_count);
        $display("--------------------------------------------");

        if (fail_count == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");

        $finish;
    end

endmodule
