`timescale 1ns / 1ps

module tb_denominator_accumulator;

    // ------------------------------------------------------------
    // Local parameters matching denominator_accumulator defaults
    // ------------------------------------------------------------
    localparam EXP_WIDTH = 15;
    localparam DEN_WIDTH = 18;

    // ------------------------------------------------------------
    // Testbench signals
    // ------------------------------------------------------------
    reg clk;
    reg rst_n;

    reg clear;
    reg add_en;

    reg  [EXP_WIDTH-1:0] exp_q;
    wire [DEN_WIDTH-1:0] den_q;

    integer errors;

    // ------------------------------------------------------------
    // Instantiate the DUT
    // DUT = Design Under Test
    // ------------------------------------------------------------
    denominator_accumulator dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .add_en(add_en),
        .exp_q(exp_q),
        .den_q(den_q)
    );

    // ------------------------------------------------------------
    // Clock generation
    // 10 ns period = 100 MHz
    // ------------------------------------------------------------
    always begin
        #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Task: add one exponent value
    // ------------------------------------------------------------
    task add_value;
        input [EXP_WIDTH-1:0] value;
        begin
            @(negedge clk);
            clear  = 1'b0;
            add_en = 1'b1;
            exp_q  = value;

            @(posedge clk);
            #1;

            @(negedge clk);
            add_en = 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // Task: check denominator value
    // ------------------------------------------------------------
    task check_den;
        input [DEN_WIDTH-1:0] expected;
        begin
            #1;

            if (den_q !== expected) begin
                $display("ERROR: expected den_q=%0d got den_q=%0d at time %0t",
                         expected, den_q, $time);
                errors = errors + 1;
            end else begin
                $display("PASS : den_q=%0d", den_q);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------
    initial begin
        $display("Starting denominator_accumulator simulation...");

        // Initial values
        clk    = 0;
        rst_n  = 1;
        clear  = 0;
        add_en = 0;
        exp_q  = 0;
        errors = 0;

        // --------------------------------------------------------
        // Test 1: Reset
        // --------------------------------------------------------
        $display("");
        $display("TEST 1: Reset should clear den_q");

        @(negedge clk);
        rst_n = 0;

        repeat (2) @(posedge clk);
        #1;

        check_den(18'd0);

        rst_n = 1;
        #1;

        // --------------------------------------------------------
        // Test 2: Add one value
        // --------------------------------------------------------
        $display("");
        $display("TEST 2: Add one value");

        add_value(15'd100);
        check_den(18'd100);

        // --------------------------------------------------------
        // Test 3: Add multiple values
        // --------------------------------------------------------
        $display("");
        $display("TEST 3: Add multiple values");

        add_value(15'd250);   // 100 + 250 = 350
        check_den(18'd350);

        add_value(15'd500);   // 350 + 500 = 850
        check_den(18'd850);

        add_value(15'd1000);  // 850 + 1000 = 1850
        check_den(18'd1850);

        add_value(15'd2000);  // 1850 + 2000 = 3850
        check_den(18'd3850);

        // --------------------------------------------------------
        // Test 4: add_en = 0 should not change den_q
        // --------------------------------------------------------
        $display("");
        $display("TEST 4: add_en = 0 should not change den_q");

        @(negedge clk);
        add_en = 1'b0;
        exp_q  = 15'd9999;

        @(posedge clk);
        #1;

        // den_q should still be 3850, not 13849
        check_den(18'd3850);

        // --------------------------------------------------------
        // Test 5: Clear
        // --------------------------------------------------------
        $display("");
        $display("TEST 5: clear should reset den_q to 0");

        @(negedge clk);
        clear = 1'b1;

        @(posedge clk);
        #1;

        check_den(18'd0);

        @(negedge clk);
        clear = 1'b0;

        // --------------------------------------------------------
        // Test 6: Add after clear
        // --------------------------------------------------------
        $display("");
        $display("TEST 6: Accumulator should work again after clear");

        add_value(15'd1234);
        check_den(18'd1234);

        add_value(15'd4321);
        check_den(18'd5555);

        // --------------------------------------------------------
        // Test 7: clear should have priority over add_en
        // --------------------------------------------------------
        $display("");
        $display("TEST 7: clear should have priority over add_en");

        @(negedge clk);
        clear  = 1'b1;
        add_en = 1'b1;
        exp_q  = 15'd7777;

        @(posedge clk);
        #1;

        // Because clear has priority, den_q should be 0, not 13332
        check_den(18'd0);

        @(negedge clk);
        clear  = 1'b0;
        add_en = 1'b0;

        // --------------------------------------------------------
        // Test 8: Large sum within 18-bit range
        // --------------------------------------------------------
        $display("");
        $display("TEST 8: Large sum test");

        add_value(15'd16000);
        check_den(18'd16000);

        add_value(15'd16000);
        check_den(18'd32000);

        add_value(15'd16000);
        check_den(18'd48000);

        add_value(15'd16000);
        check_den(18'd64000);

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------
        $display("");
        if (errors == 0) begin
            $display("============================================");
            $display("ALL TESTS PASSED for denominator_accumulator");
            $display("============================================");
        end else begin
            $display("============================================");
            $display("TEST FAILED: %0d error(s) found", errors);
            $display("============================================");
        end

        $finish;
    end

endmodule