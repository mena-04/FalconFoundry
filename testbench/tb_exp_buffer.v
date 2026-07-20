`timescale 1ns / 1ps

module tb_exp_buffer;

    // ------------------------------------------------------------
    // Local parameters matching exp_buffer defaults
    // ------------------------------------------------------------
    localparam VECTOR_LEN  = 8;
    localparam INDEX_WIDTH = 3;
    localparam EXP_WIDTH   = 15;

    // ------------------------------------------------------------
    // Testbench signals
    // ------------------------------------------------------------
    reg clk;
    reg rst_n;

    reg clear;

    reg write_en;
    reg [INDEX_WIDTH-1:0] write_addr;
    reg [EXP_WIDTH-1:0]   write_data;

    reg [INDEX_WIDTH-1:0] read_addr;
    wire [EXP_WIDTH-1:0]  read_data;

    integer i;
    integer errors;

    // ------------------------------------------------------------
    // Instantiate the DUT
    // DUT = Design Under Test
    // ------------------------------------------------------------
    exp_buffer dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_addr(read_addr),
        .read_data(read_data)
    );

    // ------------------------------------------------------------
    // Clock generation
    // 10 ns period = 100 MHz
    // ------------------------------------------------------------
    always begin
        #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Task: write one exponent value into the buffer
    // ------------------------------------------------------------
    task write_buffer;
        input [INDEX_WIDTH-1:0] addr;
        input [EXP_WIDTH-1:0] data;
        begin
            @(negedge clk);
            clear      = 1'b0;
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
        input [INDEX_WIDTH-1:0] addr;
        input [EXP_WIDTH-1:0] expected;
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
        $display("Starting exp_buffer simulation...");

        // Initial values
        clk        = 0;
        rst_n      = 1;
        clear      = 0;
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

        for (i = 0; i < VECTOR_LEN; i = i + 1) begin
            check_read(i[INDEX_WIDTH-1:0], 15'd0);
        end

        // --------------------------------------------------------
        // Test 2: Write exponent-like values
        // --------------------------------------------------------
        $display("");
        $display("TEST 2: Write exponent values");

        // These are 15-bit unsigned values.
        // They represent fixed-point exponent results.
        write_buffer(3'd0, 15'd100);
        write_buffer(3'd1, 15'd250);
        write_buffer(3'd2, 15'd500);
        write_buffer(3'd3, 15'd1000);
        write_buffer(3'd4, 15'd2000);
        write_buffer(3'd5, 15'd4000);
        write_buffer(3'd6, 15'd8000);
        write_buffer(3'd7, 15'd16000);

        // --------------------------------------------------------
        // Test 3: Read values back
        // --------------------------------------------------------
        $display("");
        $display("TEST 3: Read values back and check correctness");

        check_read(3'd0, 15'd100);
        check_read(3'd1, 15'd250);
        check_read(3'd2, 15'd500);
        check_read(3'd3, 15'd1000);
        check_read(3'd4, 15'd2000);
        check_read(3'd5, 15'd4000);
        check_read(3'd6, 15'd8000);
        check_read(3'd7, 15'd16000);

        // --------------------------------------------------------
        // Test 4: Overwrite one address
        // --------------------------------------------------------
        $display("");
        $display("TEST 4: Overwrite address 6");

        write_buffer(3'd6, 15'd12345);
        check_read(3'd6, 15'd12345);

        // Check another address did not change
        check_read(3'd5, 15'd4000);

        // --------------------------------------------------------
        // Test 5: write_en = 0 should not write
        // --------------------------------------------------------
        $display("");
        $display("TEST 5: write_en = 0 should not change memory");

        @(negedge clk);
        write_en   = 1'b0;
        write_addr = 3'd2;
        write_data = 15'd22222;

        @(posedge clk);
        #1;

        // Address 2 should still contain 500, not 22222
        check_read(3'd2, 15'd500);

        // --------------------------------------------------------
        // Test 6: Clear signal
        // --------------------------------------------------------
        $display("");
        $display("TEST 6: clear should erase all memory locations");

        @(negedge clk);
        clear = 1'b1;

        @(posedge clk);
        #1;

        @(negedge clk);
        clear = 1'b0;

        for (i = 0; i < VECTOR_LEN; i = i + 1) begin
            check_read(i[INDEX_WIDTH-1:0], 15'd0);
        end

        // --------------------------------------------------------
        // Test 7: clear has priority over write_en
        // --------------------------------------------------------
        $display("");
        $display("TEST 7: clear should have priority over write_en");

        // First write a known value to address 1
        write_buffer(3'd1, 15'd7777);
        check_read(3'd1, 15'd7777);

        // Now try to clear and write at the same time
        @(negedge clk);
        clear      = 1'b1;
        write_en   = 1'b1;
        write_addr = 3'd1;
        write_data = 15'd9999;

        @(posedge clk);
        #1;

        @(negedge clk);
        clear    = 1'b0;
        write_en = 1'b0;

        // Because clear has priority, address 1 should be 0, not 9999
        check_read(3'd1, 15'd0);

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------
        $display("");
        if (errors == 0) begin
            $display("==============================");
            $display("ALL TESTS PASSED for exp_buffer");
            $display("==============================");
        end else begin
            $display("==============================");
            $display("TEST FAILED: %0d error(s) found", errors);
            $display("==============================");
        end

        $finish;
    end

endmodule