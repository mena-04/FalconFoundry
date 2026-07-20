`timescale 1ns/1ps

module tb_exp2_hybrid_unit;

    localparam MAG_WIDTH = 9;
    localparam EXP_WIDTH = 15;

    reg  [MAG_WIDTH-1:0] magnitude;
    wire [EXP_WIDTH-1:0] exp_q;

    integer pass_count;
    integer fail_count;

    exp2_hybrid_unit #(
        .MAG_WIDTH(MAG_WIDTH),
        .EXP_WIDTH(EXP_WIDTH)
    ) dut (
        .magnitude(magnitude),
        .exp_q    (exp_q)
    );

    task automatic check_hybrid;
        input [MAG_WIDTH-1:0] magnitude_value;
        input [EXP_WIDTH-1:0] expected;
        begin
            magnitude = magnitude_value;
            #10;

            if (exp_q === expected) begin
                $display("PASS: magnitude=%0d integer=%0d fraction=%0d exp_q=%0d",
                         magnitude, magnitude[7:4], magnitude[3:0], exp_q);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL: magnitude=%0d integer=%0d fraction=%0d exp_q=%0d expected=%0d",
                         magnitude, magnitude[7:4], magnitude[3:0],
                         exp_q, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        magnitude  = 0;

        // magnitude is Q-format raw code:
        // integer_part = magnitude[7:4]
        // fractional_part = magnitude[3:0]

        check_hybrid(9'd0,  15'd16384); // 0.0000
        check_hybrid(9'd1,  15'd15690); // 0.0625
        check_hybrid(9'd4,  15'd13777); // 0.25
        check_hybrid(9'd8,  15'd11585); // 0.5
        check_hybrid(9'd15, 15'd8579);  // 0.9375

        check_hybrid(9'd16, 15'd8192);  // 1.0
        check_hybrid(9'd20, 15'd6888);  // 1.25: 13777 >> 1
        check_hybrid(9'd24, 15'd5792);  // 1.5: 11585 >> 1
        check_hybrid(9'd32, 15'd4096);  // 2.0
        check_hybrid(9'd40, 15'd2896);  // 2.5: 11585 >> 2
        check_hybrid(9'd48, 15'd2048);  // 3.0
        check_hybrid(9'd63, 15'd1072);  // 3.9375: 8579 >> 3

        $display("--------------------------------------------");
        $display("tb_exp2_hybrid_unit completed: PASS=%0d FAIL=%0d",
                 pass_count, fail_count);
        $display("--------------------------------------------");

        if (fail_count == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");

        $finish;
    end

endmodule
