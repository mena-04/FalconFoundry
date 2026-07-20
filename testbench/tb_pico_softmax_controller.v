`timescale 1ns / 1ps

`include "softmax_params.vh"

module tb_pico_softmax_controller;

    // ------------------------------------------------------------
    // Testbench signals
    // ------------------------------------------------------------
    reg clk;
    reg rst_n;

    reg start;

    reg input_valid;
    reg max_done;
    reg div_done;
    reg output_read_pulse;

    wire busy;
    wire done;

    wire input_write_en;
    wire max_start;

    wire exp_clear;
    wire exp_write_en;

    wire den_clear;
    wire den_add_en;

    wire div_start;
    wire output_write_en;

    wire [`INDEX_BITS-1:0] work_index;

    integer errors;
    integer i;
    integer timeout;
    integer store_count;

    // ------------------------------------------------------------
    // Instantiate DUT
    // ------------------------------------------------------------
    pico_softmax_controller dut (
        .clk(clk),
        .rst_n(rst_n),

        .start(start),

        .input_valid(input_valid),
        .max_done(max_done),
        .div_done(div_done),
        .output_read_pulse(output_read_pulse),

        .busy(busy),
        .done(done),

        .input_write_en(input_write_en),
        .max_start(max_start),

        .exp_clear(exp_clear),
        .exp_write_en(exp_write_en),

        .den_clear(den_clear),
        .den_add_en(den_add_en),

        .div_start(div_start),
        .output_write_en(output_write_en),

        .work_index(work_index)
    );

    // ------------------------------------------------------------
    // Clock generation
    // 10 ns period
    // ------------------------------------------------------------
    always begin
        #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Check task
    // ------------------------------------------------------------
    task check_signal;
        input condition;
        input [8*100-1:0] message;
        begin
            if (!condition) begin
                $display("ERROR: %0s at time %0t", message, $time);
                errors = errors + 1;
            end else begin
                $display("PASS : %0s", message);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Send one input_valid pulse
    //
    // Important:
    // We check input_write_en BEFORE the rising edge.
    // If we wait until after the rising edge, the FSM may already
    // move to the next state on the last input.
    // ------------------------------------------------------------
    task send_one_input;
        begin
            @(negedge clk);
            input_valid = 1'b1;
            #1;

            check_signal(input_write_en === 1'b1,
                         "input_write_en is high while input_valid is high");

            @(posedge clk);
            #1;

            @(negedge clk);
            input_valid = 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // Wait for max_start pulse
    // ------------------------------------------------------------
    task wait_for_max_start;
        begin
            timeout = 0;

            while (max_start !== 1'b1 && timeout < 30) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end

            check_signal(max_start === 1'b1,
                         "max_start pulse observed");
        end
    endtask

    // ------------------------------------------------------------
    // Pulse max_done and check clear signals
    // ------------------------------------------------------------
    task complete_max_finder;
        begin
            // Wait a little to make sure controller is in max wait area
            @(negedge clk);
            max_done = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);
            max_done = 1'b0;

            // Now wait for exp_clear / den_clear pulse
            timeout = 0;

            while ((exp_clear !== 1'b1 || den_clear !== 1'b1) && timeout < 30) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end

            check_signal(exp_clear === 1'b1,
                         "exp_clear pulse observed");
            check_signal(den_clear === 1'b1,
                         "den_clear pulse observed");
        end
    endtask

    // ------------------------------------------------------------
    // Wait for EXP_ACCUM
    // ------------------------------------------------------------
    task wait_for_exp_accum;
        begin
            timeout = 0;

            while ((exp_write_en !== 1'b1 || den_add_en !== 1'b1) && timeout < 30) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end

            check_signal(exp_write_en === 1'b1,
                         "exp_write_en observed during EXP_ACCUM");
            check_signal(den_add_en === 1'b1,
                         "den_add_en observed during EXP_ACCUM");
        end
    endtask

// Handle one division/output-store operation
//
// Correct timing:
//   1. Wait for div_start
//   2. Wait one clock so controller enters DIV_RUN
//   3. Pulse div_done while controller is in DIV_RUN
//   4. Check output_write_en in STORE_OUTPUT
// ------------------------------------------------------------
task service_one_division;
    begin
        timeout = 0;

        // Wait until controller pulses div_start
        while (div_start !== 1'b1 && timeout < 80) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end

        check_signal(div_start === 1'b1,
                     "div_start pulse observed");

        // IMPORTANT:
        // div_start is high in DIV_START.
        // The controller enters DIV_RUN on the NEXT rising edge.
        @(posedge clk);
        #1;

        // Now we are in DIV_RUN, so pulse div_done
        @(negedge clk);
        div_done = 1'b1;

        @(posedge clk);
        #1;

        // Now controller should move to STORE_OUTPUT
        check_signal(output_write_en === 1'b1,
                     "output_write_en observed after div_done");

        @(negedge clk);
        div_done = 1'b0;
    end
endtask

    // ------------------------------------------------------------
    // Read one output
    // ------------------------------------------------------------
    task read_one_output;
        begin
            @(negedge clk);
            output_read_pulse = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);
            output_read_pulse = 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------
    initial begin
        $display("Starting pico_softmax_controller simulation...");

        clk               = 0;
        rst_n             = 1;
        start             = 0;
        input_valid       = 0;
        max_done          = 0;
        div_done          = 0;
        output_read_pulse = 0;
        errors            = 0;

        // --------------------------------------------------------
        // Test 1: Reset
        // --------------------------------------------------------
        $display("");
        $display("TEST 1: Reset");

        @(negedge clk);
        rst_n = 0;

        repeat (2) @(posedge clk);
        #1;

        check_signal(busy === 1'b0,
                     "busy is 0 after reset");
        check_signal(done === 1'b0,
                     "done is 0 after reset");
        check_signal(work_index === 3'd0,
                     "work_index is 0 after reset");

        @(negedge clk);
        rst_n = 1;

        // --------------------------------------------------------
        // Test 2: Start controller
        // --------------------------------------------------------
        $display("");
        $display("TEST 2: Start controller");

        @(negedge clk);
        start = 1'b1;

        @(posedge clk);
        #1;

        @(negedge clk);
        start = 1'b0;

        @(posedge clk);
        #1;

        check_signal(busy === 1'b1,
                     "controller becomes busy after start");
        check_signal(done === 1'b0,
                     "done is 0 while controller is busy");

        // --------------------------------------------------------
        // Test 3: Load 8 inputs
        // --------------------------------------------------------
        $display("");
        $display("TEST 3: Load 8 inputs");

        for (i = 0; i < `VECTOR_LEN; i = i + 1) begin
            send_one_input();
        end

        wait_for_max_start();

        // --------------------------------------------------------
        // Test 4: Complete max finder
        // --------------------------------------------------------
        $display("");
        $display("TEST 4: Complete max finder");

        complete_max_finder();

        // --------------------------------------------------------
        // Test 5: Exponent accumulation
        // --------------------------------------------------------
        $display("");
        $display("TEST 5: Exponent accumulation");

        wait_for_exp_accum();

        // --------------------------------------------------------
        // Test 6: Division and output storage loop
        // --------------------------------------------------------
        $display("");
        $display("TEST 6: Division and output storage loop");

        for (store_count = 0; store_count < `VECTOR_LEN; store_count = store_count + 1) begin
            service_one_division();
        end

        // After 8 stores, wait for DONE
        timeout = 0;

        while (done !== 1'b1 && timeout < 50) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end

        check_signal(done === 1'b1,
                     "done is high after all outputs are stored");
        check_signal(busy === 1'b0,
                     "busy is low when done is high");

        // --------------------------------------------------------
        // Test 7: Read 8 outputs
        // --------------------------------------------------------
        $display("");
        $display("TEST 7: Read 8 outputs");

        for (i = 0; i < `VECTOR_LEN; i = i + 1) begin
            read_one_output();
        end

        // Give one clock to settle into IDLE
        @(posedge clk);
        #1;

        check_signal(done === 1'b0,
                     "done returns to 0 after all outputs are read");
        check_signal(busy === 1'b0,
                     "busy is low after returning to idle");

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------
        $display("");
        if (errors == 0) begin
            $display("==========================================");
            $display("ALL TESTS PASSED for pico_softmax_controller");
            $display("==========================================");
        end else begin
            $display("==========================================");
            $display("TEST FAILED: %0d error(s) found", errors);
            $display("==========================================");
        end

        $finish;
    end

endmodule