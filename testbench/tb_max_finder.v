`timescale 1ns/1ps

module tb_max_finder;

    reg clk;
    reg rst_n;
    reg start;
    reg signed [7:0] x_in;
    reg valid_in;
    wire done;
    wire signed [7:0] max_out;

    integer i;
    reg signed [7:0] test_vec [0:7];

    max_finder dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .x_in(x_in),
        .valid_in(valid_in),
        .done(done),
        .max_out(max_out)
    );

    always #5 clk = ~clk;

    task reset_dut;
    begin
        rst_n = 0;
        start = 0;
        valid_in = 0;
        x_in = 0;
        #50;
        rst_n = 1;
        #20;
    end
    endtask

    task run_test;
        input signed [7:0] expected;
    begin
        start = 1;
        #10;
        start = 0;

        for (i = 0; i < 8; i = i + 1) begin
            x_in = test_vec[i];
            valid_in = 1;
            #10;
            valid_in = 0;
            #10;
        end

        wait(done == 1);
        #10;

        if (max_out == expected)
            $display("PASS: max_out=%0d expected=%0d", max_out, expected);
        else
            $display("FAIL: max_out=%0d expected=%0d", max_out, expected);

        #30;
    end
    endtask

    initial begin
        clk = 0;

        reset_dut();

        test_vec[0]=1; test_vec[1]=2; test_vec[2]=3; test_vec[3]=4;
        test_vec[4]=5; test_vec[5]=6; test_vec[6]=7; test_vec[7]=8;
        run_test(8);

        reset_dut();

        test_vec[0]=-1; test_vec[1]=-3; test_vec[2]=-2; test_vec[3]=-7;
        test_vec[4]=-4; test_vec[5]=-8; test_vec[6]=-6; test_vec[7]=-5;
        run_test(-1);

        reset_dut();

        test_vec[0]=3; test_vec[1]=-2; test_vec[2]=7; test_vec[3]=1;
        test_vec[4]=0; test_vec[5]=-5; test_vec[6]=4; test_vec[7]=2;
        run_test(7);

        reset_dut();

        test_vec[0]=5; test_vec[1]=5; test_vec[2]=5; test_vec[3]=5;
        test_vec[4]=5; test_vec[5]=5; test_vec[6]=5; test_vec[7]=5;
        run_test(5);

        $display("tb_max_finder completed.");
        $stop;
    end

endmodule