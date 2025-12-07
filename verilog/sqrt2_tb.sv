`include "sqrt2.sv"

module sqrt2_tb;
    reg CLK;
    reg ENABLE;
    reg [15:0] IO_DATA_reg;
    reg should_be_inp;
    wire [15:0] IO_DATA_wire;
    wire IS_NAN_wire;
    wire IS_PINF_wire;
    wire IS_NINF_wire;
    wire RESULT_wire;

    assign IO_DATA_wire = should_be_inp ? IO_DATA_reg : 16'bz;

    sqrt2 uut (
        .IO_DATA(IO_DATA_wire),
        .IS_NAN(IS_NAN_wire),
        .IS_PINF(IS_PINF_wire),
        .IS_NINF(IS_NINF_wire),
        .RESULT(RESULT_wire),
        .CLK(CLK),
        .ENABLE(ENABLE)
    );

    reg [15:0] inp_tests [0:22];
    reg [15:0] exp_results [0:22];
    integer i, tick_count;

    initial begin
        inp_tests[0]  = 16'h4800; exp_results[0] = 16'h41a8;
        inp_tests[1]  = 16'h3400; exp_results[1] = 16'h3800;
        inp_tests[2]  = 16'hBC00; exp_results[2] = 16'hFE00;
        inp_tests[3]  = 16'hFE00; exp_results[3] = 16'hFE00;
        inp_tests[4]  = 16'h7C00; exp_results[4] = 16'h7C00;
        inp_tests[5]  = 16'h0000; exp_results[5] = 16'h0000;
        inp_tests[6]  = 16'h3C00; exp_results[6] = 16'h3C00;
        inp_tests[7]  = 16'h4000; exp_results[7] = 16'h3DA8;
        inp_tests[8]  = 16'h4200; exp_results[8] = 16'h3EED;
        inp_tests[9]  = 16'h4500; exp_results[9] = 16'h4078;
        inp_tests[10] = 16'h4700; exp_results[10] = 16'h414A;
        inp_tests[11] = 16'h0001; exp_results[11] = 16'h0C00;
        inp_tests[12] = 16'h0010; exp_results[12] = 16'h1400;
        inp_tests[13] = 16'h8000; exp_results[13] = 16'h8000;
        inp_tests[14] = 16'hC000; exp_results[14] = 16'hFE00;
        inp_tests[15] = 16'hBC00; exp_results[15] = 16'hFE00;
        inp_tests[16] = 16'hB800; exp_results[16] = 16'hFE00;
        inp_tests[17] = 16'hFC00; exp_results[17] = 16'hFE00;
        inp_tests[18] = 16'h7E00; exp_results[18] = 16'h7E00;
        inp_tests[19] = 16'h03FF; exp_results[19] = 16'h1FFE;
        inp_tests[20] = 16'h7BFF; exp_results[20] = 16'h5BFF;
        inp_tests[21] = 16'h3555; exp_results[21] = 16'h389E;
        inp_tests[22] = 16'h3E00; exp_results[22] = 16'h3CE6;
    end

    always #1 CLK = ~CLK;

    initial begin
        for (i = 0; i < 23; i = i + 1) begin
            $display("TEST %0d, Input = %h", i, inp_tests[i]);

            tick_count = 0;
            should_be_inp = 1;
            IO_DATA_reg = inp_tests[i];

            CLK = 0;
            ENABLE = 1;

            @(negedge CLK);
            should_be_inp = 0;
            IO_DATA_reg = 16'bz;

            while (RESULT_wire !== 1'b1) begin
                @(negedge CLK);
                tick_count = tick_count + 1;
                $display("    Tick %0d: IO_DATA=%h, RESULT=%b, IS_NAN=%b, IS_PINF=%b, IS_NINF=%b",
                    tick_count, IO_DATA_wire, RESULT_wire, IS_NAN_wire, IS_PINF_wire, IS_NINF_wire);
            end

            if (IO_DATA_wire == exp_results[i])
                $display("PASSED: Output = %h", IO_DATA_wire);
            else
                $display("FAILED: Output = %h, Expected = %h", IO_DATA_wire, exp_results[i]);
            
            $display();
            ENABLE = 0;
            #2;
        end

        $display();
        $finish;
    end

endmodule
