`timescale 1ns/1ps
`include "sqrt2.sv"

module sqrt2_tb;

    parameter _N = 20;

    reg CLK;
    reg ENABLE;
    reg [15:0] IO_IN;
    wire [15:0] IO_DATA;
    wire IS_NAN, IS_PINF, IS_NINF, RESULT;

    reg should_give_data;
    assign IO_DATA = should_give_data ? IO_IN : 16'hZZZZ;

    sqrt2 dut (
        IO_DATA, IS_NAN, IS_PINF, IS_NINF, RESULT, CLK, ENABLE
    );

    initial CLK = 0;
    always #1 CLK = ~CLK;

    integer fd;
    integer i;

    reg [15:0] test_inputs [0:_N-1];
    reg [15:0] test_expected [0:_N-1];

    initial begin
        // Нормальные положительные числа
        test_inputs[0]  = 16'h3C00; test_expected[0]  = 16'h3C00; // 1.0
        test_inputs[1]  = 16'h4000; test_expected[1]  = 16'h3dA8; // 2.0
        test_inputs[2]  = 16'h4200; test_expected[2]  = 16'h3EEd; // 3.0
        test_inputs[3]  = 16'h4500; test_expected[3]  = 16'h4078; // 5.0
        test_inputs[4]  = 16'h4700; test_expected[4]  = 16'h414A; // 10.0

        // Малые положительные числа (denorm)
        test_inputs[5]  = 16'h0001; test_expected[5]  = 16'h0C00; // min denorm
        test_inputs[6]  = 16'h0010; test_expected[6]  = 16'h1400; // denorm

        // Нули
        test_inputs[7]  = 16'h0000; test_expected[7]  = 16'h0000; // +0
        test_inputs[8]  = 16'h8000; test_expected[8]  = 16'h8000; // -0

        // Отрицательные числа
        test_inputs[9]  = 16'hC000; test_expected[9]  = 16'hfe00; // -2.0
        test_inputs[10] = 16'hBC00; test_expected[10] = 16'hfe00; // -1.5
        test_inputs[11] = 16'hB800; test_expected[11] = 16'hfe00; // -1.0

        // +Inf и -Inf
        test_inputs[12] = 16'h7C00; test_expected[12] = 16'h7C00; // +inf
        test_inputs[13] = 16'hFC00; test_expected[13] = 16'hfe00; // -inf

        // NaN
        test_inputs[14] = 16'h7E00; test_expected[14] = 16'h7E00; // qNaN
        test_inputs[15] = 16'hFE00; test_expected[15] = 16'hFE00; // NaN

        test_inputs[16] = 16'h03FF; test_expected[16] = 16'h1FFE; // max denorm
        test_inputs[17] = 16'h7BFF; test_expected[17] = 16'h5BFF; // max norm

        test_inputs[18] = 16'h3555; test_expected[18] = 16'h389E; // 0.3333
        test_inputs[19] = 16'h3E00; test_expected[19] = 16'h3cE6; // 1.5


        fd = $fopen("sqrt2_log.txt", "w");

        ENABLE = 0;
        should_give_data = 0;

        for (i = 0; i < _N; i = i + 1) begin
            IO_IN = test_inputs[i];

            ENABLE = 0; #2;
            ENABLE = 1;
            should_give_data = 1; #2;
            should_give_data = 0;

            $fwrite(fd, "=== Тест %0d ===\n", i);
            $fwrite(fd, "На входе число: %h\n", IO_IN);
            $fwrite(fd, "\nПромежуточные значения:\n");

            while (!RESULT) @(posedge CLK) begin
                if (dut.loaded && dut.counter_value >= 2) begin
                    $fwrite(fd, "  Такт %0d: IO_DATA = %h, RESULT = %b, IS_NAN=%b, IS_PINF=%b, IS_NINF=%b\n",
                        dut.counter_value, dut.IO_DATA, dut.RESULT, dut.IS_NAN, dut.IS_PINF, dut.IS_NINF);
                end
            end

            $fwrite(fd, "\nРезультат: IO_DATA = %h, RESULT = %b, IS_NAN=%b, IS_PINF=%b, IS_NINF=%b\n",
                        dut.IO_DATA, dut.RESULT, dut.IS_NAN, dut.IS_PINF, dut.IS_NINF);
            
            $fwrite(fd, "\nОжидалось: %h\n\n\n", test_expected[i]);

            ENABLE = 0; #2;
        end

        $fclose(fd);
        $finish;
    end

endmodule
