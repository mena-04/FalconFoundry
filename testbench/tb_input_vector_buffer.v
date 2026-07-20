`timescale 1ns / 1ps

`include "softmax_params.vh"

module tb_input_vector_buffer;

    // ------------------------------------------------------------
    // Testbench signals
    // ------------------------------------------------------------
    reg clk;
    reg rst_n;

    reg write_en;
    reg [`INDEX_BITS-1:0] write_addr;
    reg signed [`IN_BITS-1:0] write_data;

    reg [`INDEX_BITS-1:0] read_addr;
    wire signed [`IN_BITS-1:0] read_data;

    integer i;
    integer errors;

    // ------------------------------------------------------------
    // Instantiate the DUT
    // DUT = Design Under Test
    // ------------------------------------------------------------
    input_vector_buffer dut (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_addr(read_addr),
        .read_data(read_data)
    );

    // ------------------------------------------------------------
    // Clock generation
    // 10 ns period = 100 MHz clock
    // ------------------------------------------------------------
    always begin
        #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Task: write one value into the buffer
    // ------------------------------------------------------------
    task write_buffer;
        input [`INDEX_BITS-1:0] addr;
        input signed [`IN_BITS-1:0] data;
        begin
            @(negedge clk);
            write_en   = 1'b1;
            write_addr = addr;
            write_data = data;

            @(posedge clk);
            #1;

            @(negedge clk);
            write_en = 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // Task: read one address and compare with expected value
    // ------------------------------------------------------------
    task check_read;
        input [`INDEX_BITS-1:0] addr;
        input signed [`IN_BITS-1:0] expected;
        begin
            read_addr = addr;
            #1;

            if (read_data !== expected) begin
                $display("ERROR: addr=%0d expected=%0d got=%0d at time %0t",
                         addr, expected, read_data, $time);
                errors = errors + 1;
            end else begin
                $display("PASS : addr=%0d read_data=%0d", addr, read_data);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------
    initial begin
        $display("Starting input_vector_buffer simulation...");

        // Initial values
        clk        = 0;
        rst_n      = 1;
        write_en   = 0;
        write_addr = 0;
        write_data = 0;
        read_addr  = 0;
        errors     = 0;

        // --------------------------------------------------------
        // Test 1: Reset
        // --------------------------------------------------------
        $display("");
        $display("TEST 1: Reset should clear all memory locations");

        @(negedge clk);
        rst_n = 0;

        repeat (2) @(posedge clk);
        #1;

        rst_n = 1;
        #1;

        for (i = 0; i < `VECTOR_LEN; i = i + 1) begin
            check_read(i[`INDEX_BITS-1:0], 0);
        end

        // --------------------------------------------------------
        // Test 2: Write different values to all 8 addresses
        // --------------------------------------------------------
        $display("");
        $display("TEST 2: Write values to all addresses");

        write_buffer(3'd0,  8'sd10);
        write_buffer(3'd1, -8'sd5);
        write_buffer(3'd2,  8'sd20);
        write_buffer(3'd3, -8'sd15);
        write_buffer(3'd4,  8'sd30);
        write_buffer(3'd5,  8'sd40);
        write_buffer(3'd6, -8'sd25);
        write_buffer(3'd7,  8'sd7);

        // --------------------------------------------------------
        // Test 3: Read values back
        // --------------------------------------------------------
        $display("");
        $display("TEST 3: Read values back and check correctness");

        check_read(3'd0,  8'sd10);
        check_read(3'd1, -8'sd5);
        check_read(3'd2,  8'sd20);
        check_read(3'd3, -8'sd15);
        check_read(3'd4,  8'sd30);
        check_read(3'd5,  8'sd40);
        check_read(3'd6, -8'sd25);
        check_read(3'd7,  8'sd7);

        // --------------------------------------------------------
        // Test 4: Overwrite one address
        // --------------------------------------------------------
        $display("");
        $display("TEST 4: Overwrite address 3");

        write_buffer(3'd3, 8'sd99);
        check_read(3'd3, 8'sd99);

        // Also check another address did not accidentally change
        check_read(3'd2, 8'sd20);

        // --------------------------------------------------------
        // Test 5: write_en = 0 should not write
        // --------------------------------------------------------
        $display("");
        $display("TEST 5: write_en = 0 should not change memory");

        @(negedge clk);
        write_en   = 1'b0;
        write_addr = 3'd4;
        write_data = 8'sd55;

        @(posedge clk);
        #1;

        // Address 4 should still contain 30, not 55
        check_read(3'd4, 8'sd30);

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------
        $display("");
        if (errors == 0) begin
            $display("========================================");
            $display("ALL TESTS PASSED for input_vector_buffer");
            $display("========================================");
        end else begin
            $display("========================================");
            $display("TEST FAILED: %0d error(s) found", errors);
            $display("========================================");
        end

        $finish;
    end

endmodule