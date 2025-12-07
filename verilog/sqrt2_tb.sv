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

    reg [15:0] inp_tests [0:27];
    reg [15:0] exp_results [0:27];
    bool failed [0:27];
    integer i, tick_count, all_passed;

    initial begin
        // Нормальные положительные числа
        inp_tests[0]  = 16'h3C00; exp_results[0] = 16'h3C00; // 1
        inp_tests[1]  = 16'h4000; exp_results[1] = 16'h3DA8; // 2
        inp_tests[2]  = 16'h4200; exp_results[2] = 16'h3EED; // 3
        inp_tests[3]  = 16'h4500; exp_results[3] = 16'h4078; // 5
        inp_tests[4] = 16'h4700; exp_results[4] = 16'h414A; // 10
        inp_tests[5] = 16'h7BFF; exp_results[5] = 16'h5BFF; // max norm

        // Малые положительные числа (denorm)
        inp_tests[6] = 16'h0001; exp_results[6] = 16'h0C00; // min denorm
        inp_tests[7] = 16'h0010; exp_results[7] = 16'h1400; // denorm
        inp_tests[8] = 16'h03FF; exp_results[8] = 16'h1FFE; // max denorm

        // Нули
        inp_tests[9] = 16'h0000; exp_results[9] = 16'h0000; // +0
        inp_tests[10] = 16'h8000; exp_results[10] = 16'h8000; // -0

        // Отрицательные числа
        inp_tests[11] = 16'hC000; exp_results[11] = 16'hFE00; // -2
        inp_tests[12] = 16'hBC00; exp_results[12] = 16'hFE00; // -1.5
        inp_tests[13] = 16'hB800; exp_results[13] = 16'hFE00; // -1

        // +Inf и -Inf
        inp_tests[14]  = 16'h7C00; exp_results[14] = 16'h7C00; // +inf
        inp_tests[15] = 16'hFC00; exp_results[15] = 16'hFE00; // -inf

        // NaN
        inp_tests[16] = 16'h7E00; exp_results[16] = 16'h7E00; // qNaN
        inp_tests[17]  = 16'hFE00; exp_results[17] = 16'hFE00; // NaN

        // other
        inp_tests[18] = 16'h3555; exp_results[18] = 16'h389E; // 0.333
        inp_tests[19] = 16'h3E00; exp_results[19] = 16'h3CE6; // 0.5
        inp_tests[20] = 16'h4800; exp_results[20] = 16'h41A8; // 12
        inp_tests[21] = 16'h3400; exp_results[21] = 16'h3800; // 0.25
        inp_tests[22] = 16'h3A00; exp_results[22] = 16'h3AED; // 0.75
        inp_tests[23] = 16'h4600; exp_results[23] = 16'h40E6; // 6
        inp_tests[24] = 16'h4708; exp_results[24] = 16'h414D; // 10.25
        inp_tests[25] = 16'h4880; exp_results[25] = 16'h4200; // 16
        inp_tests[26] = 16'h3500; exp_results[26] = 16'h3878; // 0.3125
        inp_tests[27] = 16'h3C80; exp_results[27] = 16'h3C3E; // 1.0625
    end

    always #1 CLK = ~CLK;

    initial begin
        all_passed = 1;

        for (i = 0; i < 28; i = i + 1) begin
            $display("TEST %0d, Input = %h", i, inp_tests[i]);

            failed[i] = 0;

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

            if (IO_DATA_wire == exp_results[i]) begin
                $display("PASSED: Output = %h", IO_DATA_wire);
            end else begin
                $display("FAILED: Output = %h, Expected = %h", IO_DATA_wire, exp_results[i]);
                failed[i] = 1;
                all_passed = 0;
            end

            $display();
            ENABLE = 0;
            #2;
        end

        if (all_passed) begin
            $display("ALL PASSED");
        end else begin
            $write("FAILED TESTS: ");
            for (i = 0; i < 28; i = i + 1) begin
                if (failed[i]) begin
                    $write("%0d", i);
                    if (i < 27) $write(" ");
                end
            end
            $display("");
        end

        $display();
        $finish;
    end

endmodule
