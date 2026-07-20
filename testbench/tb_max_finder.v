`timescale 1ns/1ps

`include "softmax_params.vh"

module tb_max_finder;

    reg clk;
    reg rst_n;
    reg start;

    wire signed [`IN_BITS-1:0] x_in;
    wire [`INDEX_BITS-1:0] read_addr;
    wire signed [`IN_BITS-1:0] max_q;
    wire busy;
    wire done;

    reg signed [`IN_BITS-1:0] test_vector [0:`VECTOR_LEN-1];

    integer pass_count;
    integer fail_count;
    integer i;
    integer timeout_count;

    /*
     * The DUT controls read_addr.
     * This combinational assignment models the input vector buffer:
     * whenever read_addr changes, x_in presents that vector element.
     */
    assign x_in = test_vector[read_addr];

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

    // 100 MHz clock: 10 ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic reset_dut;
        begin
            rst_n = 1'b0;
            start = 1'b0;
            repeat (3) @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk);
        end
    endtask

    task automatic pulse_start;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task automatic wait_for_done;
        begin
            timeout_count = 0;

            while ((done !== 1'b1) &&
                   (timeout_count < (`VECTOR_LEN + 10))) begin
                @(posedge clk);
                timeout_count = timeout_count + 1;
            end

            if (done !== 1'b1) begin
                $display("ERROR: Timeout waiting for done.");
                fail_count = fail_count + 1;
            end
        end
    endtask

    task automatic check_result;
        input signed [`IN_BITS-1:0] expected_max;
        input [8*40-1:0] test_name;
        begin
            pulse_start();
            wait_for_done();
            #1;

            if (done === 1'b1 &&
                busy === 1'b0 &&
                max_q === expected_max) begin
                $display(
                    "PASS: %-24s max_q=%0d expected=%0d",
                    test_name, $signed(max_q), $signed(expected_max)
                );
                pass_count = pass_count + 1;
            end
            else if (done === 1'b1) begin
                $display(
                    "FAIL: %-24s max_q=%0d expected=%0d busy=%b done=%b",
                    test_name, $signed(max_q), $signed(expected_max),
                    busy, done
                );
                fail_count = fail_count + 1;
            end

            // done should be a one-clock pulse.
            @(posedge clk);
            #1;
            if (done !== 1'b0) begin
                $display("FAIL: done did not return low after one clock.");
                fail_count = fail_count + 1;
            end

            repeat (2) @(posedge clk);
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst_n = 1'b0;
        start = 1'b0;

        // ------------------------------------------------------------
        // Test 1: Increasing values, maximum at the last position
        // ------------------------------------------------------------
        for (i = 0; i < `VECTOR_LEN; i = i + 1)
            test_vector[i] = i + 1;

        reset_dut();
        check_result(`VECTOR_LEN, "increasing / max last");

        // ------------------------------------------------------------
        // Test 2: Decreasing values, maximum at the first position
        // ------------------------------------------------------------
        for (i = 0; i < `VECTOR_LEN; i = i + 1)
            test_vector[i] = `VECTOR_LEN - i;

        reset_dut();
        check_result(`VECTOR_LEN, "decreasing / max first");

        // ------------------------------------------------------------
        // Test 3: All-negative values
        // For VECTOR_LEN=8: {-8,-7,-6,-5,-4,-3,-2,-1}
        // Expected maximum = -1
        // ------------------------------------------------------------
        for (i = 0; i < `VECTOR_LEN; i = i + 1)
            test_vector[i] = -`VECTOR_LEN + i;

        reset_dut();
        check_result(-1, "all negative");

        // ------------------------------------------------------------
        // Test 4: All equal
        // ------------------------------------------------------------
        for (i = 0; i < `VECTOR_LEN; i = i + 1)
            test_vector[i] = -3;

        reset_dut();
        check_result(-3, "all equal");

        // ------------------------------------------------------------
        // Test 5: Mixed values, maximum in the middle
        // Requires VECTOR_LEN >= 8, as used by this project.
        // ------------------------------------------------------------
        for (i = 0; i < `VECTOR_LEN; i = i + 1)
            test_vector[i] = 0;

        test_vector[0] =  3;
        test_vector[1] = -2;
        test_vector[2] =  7;
        test_vector[3] =  1;
        test_vector[4] =  0;
        test_vector[5] = -5;
        test_vector[6] =  4;
        test_vector[7] =  2;

        reset_dut();
        check_result(7, "mixed / max middle");

        // ------------------------------------------------------------
        // Test 6: Duplicate maximum values
        // ------------------------------------------------------------
        for (i = 0; i < `VECTOR_LEN; i = i + 1)
            test_vector[i] = -2;

        test_vector[1] = 6;
        test_vector[5] = 6;

        reset_dut();
        check_result(6, "duplicate maximum");

        $display("--------------------------------------------");
        $display("tb_max_finder completed: PASS=%0d FAIL=%0d",
                 pass_count, fail_count);
        $display("--------------------------------------------");

        if (fail_count == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");

        $finish;
    end

endmodule
