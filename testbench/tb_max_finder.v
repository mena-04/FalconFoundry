`timescale 1ns/1ps

`include "softmax_params.vh"

module tb_max_finder;

    // ----------------------------------------------------------------
    // Testbench signals
    // ----------------------------------------------------------------
    reg clk;
    reg rst_n;
    reg start;

    wire signed [`IN_BITS-1:0] x_in;
    wire [`INDEX_BITS-1:0]     read_addr;
    wire signed [`IN_BITS-1:0] max_q;
    wire                       busy;
    wire                       done;

    // Simulated input vector buffer
    reg signed [`IN_BITS-1:0] test_vector [0:`VECTOR_LEN-1];

    integer pass_count;
    integer fail_count;
    integer i;
    integer timeout_count;

    // ----------------------------------------------------------------
    // The DUT generates read_addr.
    // This assignment emulates the input vector buffer output.
    // ----------------------------------------------------------------
    assign x_in = test_vector[read_addr];

    // ----------------------------------------------------------------
    // DUT
    // ----------------------------------------------------------------
    max_finder dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (start),
        .x_in     (x_in),
        .read_addr(read_addr),
        .max_q    (max_q),
        .busy     (busy),
        .done     (done)
    );

    // ----------------------------------------------------------------
    // Clock: 10 ns period = 100 MHz
    // ----------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ----------------------------------------------------------------
    // Reset task
    // ----------------------------------------------------------------
    task automatic reset_dut;
        begin
            start = 1'b0;
            rst_n = 1'b0;

            repeat (3) @(posedge clk);

            rst_n = 1'b1;
            @(negedge clk);
        end
    endtask

    // ----------------------------------------------------------------
    // Start pulse task
    // ----------------------------------------------------------------
    task automatic pulse_start;
        begin
            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;
        end
    endtask

    // ----------------------------------------------------------------
    // Wait until done becomes high.
    // Sampling is done on the falling edge so that all nonblocking
    // assignments from the preceding rising edge have settled.
    // ----------------------------------------------------------------
    task automatic wait_for_done;
        output reg timed_out;
        begin
            timeout_count = 0;
            timed_out = 1'b0;

            while ((done !== 1'b1) &&
                   (timeout_count < (`VECTOR_LEN + 10))) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
            end

            if (done !== 1'b1) begin
                timed_out = 1'b1;
            end
        end
    endtask

    // ----------------------------------------------------------------
    // Check one complete vector
    // ----------------------------------------------------------------
    task automatic run_test;
        input signed [`IN_BITS-1:0] expected_max;
        input [8*40-1:0] test_name;

        reg timed_out;
        begin
            pulse_start();
            wait_for_done(timed_out);
            #1;

            if (timed_out) begin
                $display(
                    "FAIL: %-24s timeout waiting for done",
                    test_name
                );
                fail_count = fail_count + 1;
            end
            else if ((busy === 1'b0) &&
                     (done === 1'b1) &&
                     (max_q === expected_max)) begin
                $display(
                    "PASS: %-24s max_q=%0d expected=%0d",
                    test_name,
                    $signed(max_q),
                    $signed(expected_max)
                );
                pass_count = pass_count + 1;
            end
            else begin
                $display(
                    "FAIL: %-24s max_q=%0d expected=%0d busy=%b done=%b read_addr=%0d",
                    test_name,
                    $signed(max_q),
                    $signed(expected_max),
                    busy,
                    done,
                    read_addr
                );
                fail_count = fail_count + 1;
            end

            // Confirm that done is only a one-clock pulse.
            @(negedge clk);
            #1;

            if (done !== 1'b0) begin
                $display(
                    "FAIL: %-24s done did not return low after one clock",
                    test_name
                );
                fail_count = fail_count + 1;
            end

            // Small idle gap before the next test.
            repeat (2) @(posedge clk);
        end
    endtask

    // ----------------------------------------------------------------
    // Test sequence
    // ----------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        rst_n      = 1'b0;
        start      = 1'b0;

        // ============================================================
        // Test 1: Increasing values, maximum at the last position
        // For VECTOR_LEN=8: 1,2,3,4,5,6,7,8
        // ============================================================
        for (i = 0; i < `VECTOR_LEN; i = i + 1) begin
            test_vector[i] = i + 1;
        end

        reset_dut();
        run_test(`VECTOR_LEN, "increasing / max last");

        // ============================================================
        // Test 2: Decreasing values, maximum at the first position
        // For VECTOR_LEN=8: 8,7,6,5,4,3,2,1
        // ============================================================
        for (i = 0; i < `VECTOR_LEN; i = i + 1) begin
            test_vector[i] = `VECTOR_LEN - i;
        end

        reset_dut();
        run_test(`VECTOR_LEN, "decreasing / max first");

        // ============================================================
        // Test 3: All negative
        // For VECTOR_LEN=8: -8,-7,-6,-5,-4,-3,-2,-1
        // ============================================================
        for (i = 0; i < `VECTOR_LEN; i = i + 1) begin
            test_vector[i] = -`VECTOR_LEN + i;
        end

        reset_dut();
        run_test(-1, "all negative");

        // ============================================================
        // Test 4: All equal
        // ============================================================
        for (i = 0; i < `VECTOR_LEN; i = i + 1) begin
            test_vector[i] = -3;
        end

        reset_dut();
        run_test(-3, "all equal");

        // ============================================================
        // Test 5: Mixed values, maximum in the middle
        // Requires VECTOR_LEN >= 8 for this project.
        // ============================================================
        for (i = 0; i < `VECTOR_LEN; i = i + 1) begin
            test_vector[i] = 0;
        end

        test_vector[0] =  3;
        test_vector[1] = -2;
        test_vector[2] =  7;
        test_vector[3] =  1;
        test_vector[4] =  0;
        test_vector[5] = -5;
        test_vector[6] =  4;
        test_vector[7] =  2;

        reset_dut();
        run_test(7, "mixed / max middle");

        // ============================================================
        // Test 6: Duplicate maximum
        // ============================================================
        for (i = 0; i < `VECTOR_LEN; i = i + 1) begin
            test_vector[i] = -2;
        end

        test_vector[1] = 6;
        test_vector[5] = 6;

        reset_dut();
        run_test(6, "duplicate maximum");

        // ----------------------------------------------------------------
        // Final summary
        // ----------------------------------------------------------------
        $display("--------------------------------------------");
        $display(
            "tb_max_finder completed: PASS=%0d FAIL=%0d",
            pass_count,
            fail_count
        );
        $display("--------------------------------------------");

        if (fail_count == 0) begin
            $display("OVERALL RESULT: PASS");
        end
        else begin
            $display("OVERALL RESULT: FAIL");
        end

        $finish;
    end

endmodule
