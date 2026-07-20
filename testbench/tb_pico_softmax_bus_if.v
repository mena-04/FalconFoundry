`timescale 1ns / 1ps

`include "softmax_params.vh"

module tb_pico_softmax_bus_if;

    // ------------------------------------------------------------
    // Testbench signals
    // ------------------------------------------------------------
    reg clk;
    reg rst_n;

    reg wr_en;
    reg rd_en;

    wire [`OUT_BITS-1:0] data_bus;

    wire input_valid;
    wire [`INDEX_BITS-1:0] input_index;
    wire signed [`IN_BITS-1:0] input_data;

    wire [`INDEX_BITS-1:0] output_index;
    reg  [`OUT_BITS-1:0] output_data;

    wire output_read_pulse;

    integer errors;
    integer i;

    // ------------------------------------------------------------
    // Host-side data bus driver
    //
    // The DUT and the testbench share data_bus.
    //
    // During write mode:
    //   host_drive_en = 1
    //   testbench drives data_bus
    //
    // During read mode:
    //   host_drive_en = 0
    //   DUT drives data_bus
    // ------------------------------------------------------------
    reg [`OUT_BITS-1:0] host_data_out;
    reg host_drive_en;

    assign data_bus = host_drive_en ? host_data_out : {`OUT_BITS{1'bz}};

    // ------------------------------------------------------------
    // Instantiate DUT
    // ------------------------------------------------------------
    pico_softmax_bus_if dut (
        .clk(clk),
        .rst_n(rst_n),

        .wr_en(wr_en),
        .rd_en(rd_en),

        .data_bus(data_bus),

        .input_valid(input_valid),
        .input_index(input_index),
        .input_data(input_data),

        .output_index(output_index),
        .output_data(output_data),

        .output_read_pulse(output_read_pulse)
    );

    // ------------------------------------------------------------
    // Clock generation
    // 10 ns period = 100 MHz
    // ------------------------------------------------------------
    always begin
        #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Task: host writes one byte into the chip
    // ------------------------------------------------------------
    task host_write;
        input [`OUT_BITS-1:0] value;
        input [`INDEX_BITS-1:0] expected_index;
        begin
            @(negedge clk);

            host_drive_en = 1'b1;
            host_data_out = value;

            wr_en = 1'b1;
            rd_en = 1'b0;

            @(posedge clk);
            #1;

            if (input_valid !== 1'b1) begin
                $display("ERROR: input_valid should be 1 during write at time %0t", $time);
                errors = errors + 1;
            end

            if (input_index !== expected_index) begin
                $display("ERROR: expected input_index=%0d got=%0d at time %0t",
                         expected_index, input_index, $time);
                errors = errors + 1;
            end

            if (input_data !== value[`IN_BITS-1:0]) begin
                $display("ERROR: expected input_data=%0d got=%0d at time %0t",
                         value[`IN_BITS-1:0], input_data, $time);
                errors = errors + 1;
            end

            if (input_valid === 1'b1 &&
                input_index === expected_index &&
                input_data === value[`IN_BITS-1:0]) begin
                $display("PASS : write value=%0d input_index=%0d input_data=%0d",
                         value, input_index, input_data);
            end

            @(negedge clk);
            wr_en = 1'b0;
            host_drive_en = 1'b0;
            host_data_out = 0;
        end
    endtask

    // ------------------------------------------------------------
    // Task: host reads one byte from the chip
    // ------------------------------------------------------------
    task host_read;
        input [`OUT_BITS-1:0] value_from_chip;
        input [`INDEX_BITS-1:0] expected_index;
        begin
            @(negedge clk);

            host_drive_en = 1'b0;   // release bus so DUT can drive it
            output_data   = value_from_chip;

            wr_en = 1'b0;
            rd_en = 1'b1;

            @(posedge clk);
            #1;

            if (output_read_pulse !== 1'b1) begin
                $display("ERROR: output_read_pulse should be 1 during read at time %0t", $time);
                errors = errors + 1;
            end

            if (output_index !== expected_index) begin
                $display("ERROR: expected output_index=%0d got=%0d at time %0t",
                         expected_index, output_index, $time);
                errors = errors + 1;
            end

            if (data_bus !== value_from_chip) begin
                $display("ERROR: expected data_bus=%0d got=%0d at time %0t",
                         value_from_chip, data_bus, $time);
                errors = errors + 1;
            end

            if (output_read_pulse === 1'b1 &&
                output_index === expected_index &&
                data_bus === value_from_chip) begin
                $display("PASS : read output_index=%0d data_bus=%0d",
                         output_index, data_bus);
            end

            @(negedge clk);
            rd_en = 1'b0;
            output_data = 0;
        end
    endtask

    // ------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------
    initial begin
        $display("Starting pico_softmax_bus_if simulation...");

        // Initial values
        clk           = 0;
        rst_n         = 1;
        wr_en         = 0;
        rd_en         = 0;
        output_data   = 0;
        host_data_out = 0;
        host_drive_en = 0;
        errors        = 0;

        // --------------------------------------------------------
        // Test 1: Reset
        // --------------------------------------------------------
        $display("");
        $display("TEST 1: Reset should clear indexes and pulses");

        @(negedge clk);
        rst_n = 0;

        repeat (2) @(posedge clk);
        #1;

        if (input_valid !== 1'b0) begin
            $display("ERROR: input_valid should be 0 after reset");
            errors = errors + 1;
        end

        if (input_index !== 3'd0) begin
            $display("ERROR: input_index should be 0 after reset");
            errors = errors + 1;
        end

        if (input_data !== 8'd0) begin
            $display("ERROR: input_data should be 0 after reset");
            errors = errors + 1;
        end

        if (output_index !== 3'd0) begin
            $display("ERROR: output_index should be 0 after reset");
            errors = errors + 1;
        end

        if (output_read_pulse !== 1'b0) begin
            $display("ERROR: output_read_pulse should be 0 after reset");
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("PASS : reset values are correct");
        end

        rst_n = 1;
        #1;

        // --------------------------------------------------------
        // Test 2: Host writes 8 input values
        // --------------------------------------------------------
        $display("");
        $display("TEST 2: Host writes 8 input values");

        host_write(8'd10, 3'd1);
        host_write(8'd20, 3'd2);
        host_write(8'd30, 3'd3);
        host_write(8'd40, 3'd4);
        host_write(8'd50, 3'd5);
        host_write(8'd60, 3'd6);
        host_write(8'd70, 3'd7);
        host_write(8'd80, 3'd0);

        // Important note:
        // input_index is incremented in the same clock cycle as the write.
        // So after writing the first value, input_index becomes 1.
        // That is why the expected indexes above are 1,2,3,...,0.

        // --------------------------------------------------------
        // Test 3: input_valid should return to 0 after write
        // --------------------------------------------------------
        $display("");
        $display("TEST 3: input_valid should be a one-cycle pulse");

        @(posedge clk);
        #1;

        if (input_valid !== 1'b0) begin
            $display("ERROR: input_valid should return to 0");
            errors = errors + 1;
        end else begin
            $display("PASS : input_valid returned to 0");
        end

        // --------------------------------------------------------
        // Test 4: Host reads 8 output values
        // --------------------------------------------------------
        $display("");
        $display("TEST 4: Host reads 8 output values");

        host_read(8'd5,   3'd1);
        host_read(8'd15,  3'd2);
        host_read(8'd25,  3'd3);
        host_read(8'd35,  3'd4);
        host_read(8'd45,  3'd5);
        host_read(8'd55,  3'd6);
        host_read(8'd65,  3'd7);
        host_read(8'd75,  3'd0);

        // Same idea:
        // output_index increments during the read clock edge.
        // So the observed value after the first read is 1.

        // --------------------------------------------------------
        // Test 5: output_read_pulse should return to 0 after read
        // --------------------------------------------------------
        $display("");
        $display("TEST 5: output_read_pulse should be a one-cycle pulse");

        @(posedge clk);
        #1;

        if (output_read_pulse !== 1'b0) begin
            $display("ERROR: output_read_pulse should return to 0");
            errors = errors + 1;
        end else begin
            $display("PASS : output_read_pulse returned to 0");
        end

        // --------------------------------------------------------
        // Test 6: wr_en and rd_en both high should do nothing
        // --------------------------------------------------------
        $display("");
        $display("TEST 6: wr_en and rd_en both high should do nothing");

        @(negedge clk);
        host_drive_en = 1'b1;
        host_data_out = 8'd99;
        output_data   = 8'd123;
        wr_en = 1'b1;
        rd_en = 1'b1;

        @(posedge clk);
        #1;

        if (input_valid !== 1'b0) begin
            $display("ERROR: input_valid should stay 0 when wr_en and rd_en are both high");
            errors = errors + 1;
        end

        if (output_read_pulse !== 1'b0) begin
            $display("ERROR: output_read_pulse should stay 0 when wr_en and rd_en are both high");
            errors = errors + 1;
        end

        if (input_valid === 1'b0 && output_read_pulse === 1'b0) begin
            $display("PASS : both-high case does nothing");
        end

        @(negedge clk);
        wr_en = 1'b0;
        rd_en = 1'b0;
        host_drive_en = 1'b0;

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------
        $display("");
        if (errors == 0) begin
            $display("=======================================");
            $display("ALL TESTS PASSED for pico_softmax_bus_if");
            $display("=======================================");
        end else begin
            $display("=======================================");
            $display("TEST FAILED: %0d error(s) found", errors);
            $display("=======================================");
        end

        $finish;
    end

endmodule