`timescale 1ns / 1ps

`include "softmax_params.vh"

module tb_pico_softmax;

    // ============================================================
    // Testbench signals
    // ============================================================

    reg clk;
    reg rst_n;
    reg start;
    reg wr_en;
    reg rd_en;

    reg  [`OUT_BITS-1:0] data_drive;
    wire [`OUT_BITS-1:0] data_bus;

    wire busy;
    wire done;

    // ============================================================
    // Test vectors
    // ============================================================

    reg signed [`IN_BITS-1:0] input_vector
        [0:`VECTOR_LEN-1];

    reg [`OUT_BITS-1:0] expected_vector
        [0:`VECTOR_LEN-1];

    reg [`OUT_BITS-1:0] actual_vector
        [0:`VECTOR_LEN-1];

    // ============================================================
    // Testbench counters
    // ============================================================

    integer test_id;
    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    integer vector_errors;
    integer abs_error;
    integer max_error;

    // ============================================================
    // Bidirectional bus driver
    //
    // The testbench drives data_bus only when wr_en is high.
    // During reads, the testbench releases the bus and the DUT
    // drives it.
    // ============================================================

    assign data_bus =
        wr_en
        ? data_drive
        : {`OUT_BITS{1'bz}};

    // ============================================================
    // Device under test
    // ============================================================

    pico_softmax_top dut (
        .clk      (clk),
        .rst_n    (rst_n),

        .start    (start),
        .wr_en    (wr_en),
        .rd_en    (rd_en),

        .data_bus (data_bus),

        .busy     (busy),
        .done     (done)
    );

    // ============================================================
    // Clock generation
    //
    // Period = 10 ns
    // Frequency = 100 MHz
    // ============================================================

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    // ============================================================
    // Reset task
    // ============================================================

    task reset_dut;
    begin
        rst_n      = 1'b0;
        start      = 1'b0;
        wr_en      = 1'b0;
        rd_en      = 1'b0;
        data_drive = {`OUT_BITS{1'b0}};

        repeat (5) begin
            @(posedge clk);
        end

        @(negedge clk);
        rst_n = 1'b1;

        repeat (2) begin
            @(posedge clk);
        end
    end
    endtask

    // ============================================================
    // Begin transaction
    //
    // The current controller leaves IDLE when start is asserted.
    // Therefore, start is pulsed before the eight input writes.
    // ============================================================

    task begin_transaction;
    begin
        @(negedge clk);
        start = 1'b1;

        @(posedge clk);

        @(negedge clk);
        start = 1'b0;

        // Wait one clock for the controller to enter LOAD_INPUTS.
        @(posedge clk);

        if (busy !== 1'b1) begin
            $display(
                "ERROR: Controller did not enter the busy/load phase."
            );
        end
    end
    endtask

    // ============================================================
    // Write one byte to the input bus
    // ============================================================

    task write_byte;
        input [`IN_BITS-1:0] value;
    begin
        @(negedge clk);

        data_drive = value;
        rd_en      = 1'b0;
        wr_en      = 1'b1;

        @(posedge clk);

        @(negedge clk);

        wr_en      = 1'b0;
        data_drive = {`OUT_BITS{1'b0}};

        /*
            input_valid is registered by the bus interface.

            Leave one additional clock for the controller and
            input buffer write handshake to complete.
        */

        @(posedge clk);
    end
    endtask

    // ============================================================
    // Load all eight input values
    // ============================================================

    task load_vector;
        integer k;
    begin
        $display("Loading input vector...");

        for (k = 0; k < `VECTOR_LEN; k = k + 1) begin
            write_byte(input_vector[k]);

            $display(
                "Input[%0d] = %0d, raw byte = 0x%02h",
                k,
                $signed(input_vector[k]),
                input_vector[k]
            );
        end
    end
    endtask

    // ============================================================
    // Wait for computation completion
    //
    // Timeout prevents the simulation from running forever if the
    // FSM becomes stuck.
    // ============================================================

    task wait_for_done;
        integer timeout_cycles;
    begin
        timeout_cycles = 0;

        $display("Waiting for done...");

        while (
            (done !== 1'b1) &&
            (timeout_cycles < 2000)
        ) begin
            @(posedge clk);

            timeout_cycles =
                timeout_cycles + 1;
        end

        if (done !== 1'b1) begin
            $display("");
            $display(
                "ERROR: Timeout waiting for done after %0d cycles.",
                timeout_cycles
            );

            $display(
                "busy=%b state=%0d work_index=%0d",
                busy,
                dut.controller_inst.state,
                dut.work_index
            );

            $finish;
        end

        $display(
            "Computation completed in %0d wait cycles.",
            timeout_cycles
        );
    end
    endtask

    // ============================================================
    // Read one output byte
    // ============================================================

    task read_byte;
        input integer index;
    begin
        @(negedge clk);

        wr_en = 1'b0;
        rd_en = 1'b1;

        /*
            The bus interface registers the output data and output
            enable at the next rising edge.
        */

        @(posedge clk);

        #1;
        actual_vector[index] = data_bus;

        $display(
            "Output[%0d] = %0d, raw byte = 0x%02h",
            index,
            actual_vector[index],
            actual_vector[index]
        );

        @(negedge clk);
        rd_en = 1'b0;

        @(posedge clk);
    end
    endtask

    // ============================================================
    // Read all eight outputs
    // ============================================================

    task read_vector;
        integer k;
    begin
        $display("Reading output vector...");

        for (k = 0; k < `VECTOR_LEN; k = k + 1) begin
            read_byte(k);
        end
    end
    endtask

    // ============================================================
    // Compare actual RTL outputs with expected outputs
    // ============================================================

    task compare_vector;
        input integer test_number;

        integer k;
        integer signed_difference;
    begin
        vector_errors = 0;
        max_error     = 0;

        $display("");
        $display(
            "------------------------------------------------------------"
        );

        $display(
            " Index | Input(raw) | Expected | Actual | Abs Error | Status"
        );

        $display(
            "------------------------------------------------------------"
        );

        for (k = 0; k < `VECTOR_LEN; k = k + 1) begin

            signed_difference =
                actual_vector[k] -
                expected_vector[k];

            if (signed_difference < 0) begin
                abs_error = -signed_difference;
            end else begin
                abs_error = signed_difference;
            end

            if (abs_error > max_error) begin
                max_error = abs_error;
            end

            if (
                actual_vector[k] ===
                expected_vector[k]
            ) begin
                $display(
                    "   %0d   |    %4d    |   %3d    |  %3d   |     %0d     | PASS",
                    k,
                    $signed(input_vector[k]),
                    expected_vector[k],
                    actual_vector[k],
                    abs_error
                );
            end else begin
                $display(
                    "   %0d   |    %4d    |   %3d    |  %3d   |     %0d     | FAIL",
                    k,
                    $signed(input_vector[k]),
                    expected_vector[k],
                    actual_vector[k],
                    abs_error
                );

                vector_errors =
                    vector_errors + 1;
            end
        end

        $display(
            "------------------------------------------------------------"
        );

        $display(
            "max_q=%0d den_q=%0d maximum output error=%0d LSB",
            $signed(dut.max_q),
            dut.den_q,
            max_error
        );

        if (vector_errors == 0) begin
            passed_tests =
                passed_tests + 1;

            $display(
                "TEST %0d PASSED",
                test_number
            );
        end else begin
            failed_tests =
                failed_tests + 1;

            $display(
                "TEST %0d FAILED: %0d mismatching output(s)",
                test_number,
                vector_errors
            );
        end

        $display("");
    end
    endtask

    // ============================================================
    // Run one complete top-level test
    // ============================================================

    task run_test;
        input integer test_number;
    begin
        total_tests =
            total_tests + 1;

        $display("");
        $display(
            "============================================================"
        );

        $display(
            "RUNNING TEST %0d",
            test_number
        );

        $display(
            "============================================================"
        );

        $display("Step 1: Reset DUT");
        reset_dut;

        $display("Step 2: Begin transaction");
        begin_transaction;

        $display("Step 3: Load input vector");
        load_vector;

        $display("Step 4: Wait for completion");
        wait_for_done;

        $display("Step 5: Read output vector");
        read_vector;

        $display("Step 6: Compare outputs");
        compare_vector(test_number);
    end
    endtask

    // ============================================================
    // Select test vectors
    //
    // Inputs are raw signed Q3.4 values.
    // Outputs are unsigned Q0.8 values.
    // ============================================================

    task select_test;
        input integer test_number;

        integer k;
    begin
        case (test_number)

            // ----------------------------------------------------
            // Test 1: All values equal to 1.0
            //
            // Q3.4:
            //     1.0 x 16 = 16
            //
            // Expected:
            //     1/8 x 256 = 32
            // ----------------------------------------------------

            1: begin
                for (
                    k = 0;
                    k < `VECTOR_LEN;
                    k = k + 1
                ) begin
                    input_vector[k] =
                        8'sd16;

                    expected_vector[k] =
                        8'd32;
                end
            end

            // ----------------------------------------------------
            // Test 2: Increasing values
            // ----------------------------------------------------

            2: begin
                input_vector[0] = 8'sd16;
                input_vector[1] = 8'sd32;
                input_vector[2] = 8'sd48;
                input_vector[3] = 8'sd64;
                input_vector[4] = 8'sd80;
                input_vector[5] = 8'sd96;
                input_vector[6] = 8'sd112;
                input_vector[7] = 8'sd127;

                expected_vector[0] = 8'd1;
                expected_vector[1] = 8'd2;
                expected_vector[2] = 8'd4;
                expected_vector[3] = 8'd8;
                expected_vector[4] = 8'd16;
                expected_vector[5] = 8'd32;
                expected_vector[6] = 8'd65;
                expected_vector[7] = 8'd125;
            end

            // ----------------------------------------------------
            // Test 3: Decreasing values
            // ----------------------------------------------------

            3: begin
                input_vector[0] = 8'sd127;
                input_vector[1] = 8'sd112;
                input_vector[2] = 8'sd96;
                input_vector[3] = 8'sd80;
                input_vector[4] = 8'sd64;
                input_vector[5] = 8'sd48;
                input_vector[6] = 8'sd32;
                input_vector[7] = 8'sd16;

                expected_vector[0] = 8'd125;
                expected_vector[1] = 8'd65;
                expected_vector[2] = 8'd32;
                expected_vector[3] = 8'd16;
                expected_vector[4] = 8'd8;
                expected_vector[5] = 8'd4;
                expected_vector[6] = 8'd2;
                expected_vector[7] = 8'd1;
            end

            // ----------------------------------------------------
            // Test 4: Negative values
            //
            // 8'h80 is the two's-complement representation of -128.
            // ----------------------------------------------------

            4: begin
                input_vector[0] = 8'sh80;
                input_vector[1] = -8'sd112;
                input_vector[2] = -8'sd96;
                input_vector[3] = -8'sd80;
                input_vector[4] = -8'sd64;
                input_vector[5] = -8'sd48;
                input_vector[6] = -8'sd32;
                input_vector[7] = -8'sd16;

                expected_vector[0] = 8'd1;
                expected_vector[1] = 8'd2;
                expected_vector[2] = 8'd4;
                expected_vector[3] = 8'd8;
                expected_vector[4] = 8'd16;
                expected_vector[5] = 8'd32;
                expected_vector[6] = 8'd64;
                expected_vector[7] = 8'd128;
            end

            // ----------------------------------------------------
            // Test 5: Mixed positive and negative values
            // ----------------------------------------------------

            5: begin
                input_vector[0] = 8'sd32;
                input_vector[1] = -8'sd16;
                input_vector[2] = 8'sd112;
                input_vector[3] = 8'sd0;
                input_vector[4] = -8'sd64;
                input_vector[5] = 8'sd80;
                input_vector[6] = 8'sd16;
                input_vector[7] = -8'sd32;

                expected_vector[0] = 8'd6;
                expected_vector[1] = 8'd0;
                expected_vector[2] = 8'd195;
                expected_vector[3] = 8'd1;
                expected_vector[4] = 8'd0;
                expected_vector[5] = 8'd48;
                expected_vector[6] = 8'd3;
                expected_vector[7] = 8'd0;
            end

            // ----------------------------------------------------
            // Test 6: One dominant value
            // ----------------------------------------------------

            6: begin
                input_vector[0] =
                    8'sd112;

                for (
                    k = 1;
                    k < `VECTOR_LEN;
                    k = k + 1
                ) begin
                    input_vector[k] =
                        8'sd0;
                end

                expected_vector[0] =
                    8'd242;

                for (
                    k = 1;
                    k < `VECTOR_LEN;
                    k = k + 1
                ) begin
                    expected_vector[k] =
                        8'd1;
                end
            end

            // ----------------------------------------------------
            // Default test
            // ----------------------------------------------------

            default: begin
                for (
                    k = 0;
                    k < `VECTOR_LEN;
                    k = k + 1
                ) begin
                    input_vector[k] =
                        8'sd0;

                    expected_vector[k] =
                        8'd32;
                end
            end

        endcase

        // Clear previously captured outputs.

        for (
            k = 0;
            k < `VECTOR_LEN;
            k = k + 1
        ) begin
            actual_vector[k] =
                {`OUT_BITS{1'b0}};
        end
    end
    endtask

    // ============================================================
    // Main test sequence
    // ============================================================

    initial begin
        $display(
            "tb_pico_softmax started at simulation time %0t",
            $time
        );

        rst_n        = 1'b0;
        start        = 1'b0;
        wr_en        = 1'b0;
        rd_en        = 1'b0;
        data_drive   = {`OUT_BITS{1'b0}};

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        /*
            Use test_id for the outer loop.

            select_test uses its own local variable k, so the outer
            test counter cannot be overwritten.
        */

        for (
            test_id = 1;
            test_id <= 6;
            test_id = test_id + 1
        ) begin
            select_test(test_id);
            run_test(test_id);
        end

        $display("");
        $display(
            "============================================================"
        );

        $display(
            "FINAL VERIFICATION SUMMARY"
        );

        $display(
            "============================================================"
        );

        $display(
            "Total tests : %0d",
            total_tests
        );

        $display(
            "Passed      : %0d",
            passed_tests
        );

        $display(
            "Failed      : %0d",
            failed_tests
        );

        if (failed_tests == 0) begin
            $display(
                "OVERALL RESULT: PASS"
            );
        end else begin
            $display(
                "OVERALL RESULT: FAIL"
            );
        end

        $display(
            "============================================================"
        );

        $display("");

        repeat (5) begin
            @(posedge clk);
        end

        $finish;
    end

endmodule