`timescale 1ns/1ps

module tb_delta_unit;

    localparam IN_WIDTH  = 8;
    localparam MAG_WIDTH = 9;

    reg  signed [IN_WIDTH-1:0]  x_q;
    reg  signed [IN_WIDTH-1:0]  max_q;

    wire signed [MAG_WIDTH-1:0] delta_q;
    wire        [MAG_WIDTH-1:0] magnitude;

    integer pass_count;
    integer fail_count;

    delta_unit #(
        .IN_WIDTH (IN_WIDTH),
        .MAG_WIDTH(MAG_WIDTH)
    ) dut (
        .x_q      (x_q),
        .max_q    (max_q),
        .delta_q  (delta_q),
        .magnitude(magnitude)
    );

    task automatic check_delta;
        input signed [IN_WIDTH-1:0]  x_val;
        input signed [IN_WIDTH-1:0]  max_val;
        input signed [MAG_WIDTH-1:0] expected_delta;
        input        [MAG_WIDTH-1:0] expected_magnitude;
        begin
            x_q   = x_val;
            max_q = max_val;
            #10;

            if ((delta_q === expected_delta) &&
                (magnitude === expected_magnitude)) begin
                $display("PASS: x=%0d max=%0d delta=%0d magnitude=%0d",
                         $signed(x_q), $signed(max_q),
                         $signed(delta_q), magnitude);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL: x=%0d max=%0d delta=%0d expected_delta=%0d magnitude=%0d expected_magnitude=%0d",
                         $signed(x_q), $signed(max_q),
                         $signed(delta_q), $signed(expected_delta),
                         magnitude, expected_magnitude);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        x_q         = 0;
        max_q       = 0;

        // Your RTL defines:
        // delta_q   = x_q - max_q
        // magnitude = abs(delta_q)

        check_delta( 8'sd2,  8'sd6, -9'sd4,  9'd4);
        check_delta( 8'sd6,  8'sd6,  9'sd0,  9'd0);
        check_delta( 8'sd1,  8'sd6, -9'sd5,  9'd5);
        check_delta(-8'sd4, -8'sd1, -9'sd3,  9'd3);
        check_delta(-8'sd2,  8'sd7, -9'sd9,  9'd9);

        // Q3.4 raw-code examples
        check_delta( 8'sd16, 8'sd32, -9'sd16, 9'd16);
        check_delta(-8'sd8,  8'sd24, -9'sd32, 9'd32);

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
