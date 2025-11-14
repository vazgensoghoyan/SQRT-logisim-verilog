`timescale 1ns/1ps
`include "sqrt2.sv"

module sqrt2_tb;

    reg CLK;
    reg ENABLE;
    reg [15:0] IO_IN;
    wire [15:0] IO_DATA;
    wire IS_NAN, IS_PINF, IS_NINF, RESULT;

    reg drive_io;
    assign IO_DATA = drive_io ? IO_IN : 16'hZZZZ;

    sqrt2 dut (
        IO_DATA, IS_NAN, IS_PINF, IS_NINF, RESULT, CLK, ENABLE
    );

    initial CLK = 0;
    always #1 CLK = ~CLK;

    integer fd;
    integer i;

    reg [15:0] test_inputs [0:5];
    reg [15:0] test_expected [0:5];

    initial begin
        test_inputs[0] = 16'h3C00; test_expected[0] = 16'h3C00;
        test_inputs[1] = 16'h0000; test_expected[1] = 16'h0000;
        test_inputs[2] = 16'h4000; test_expected[2] = 16'h4200;
        test_inputs[3] = 16'h7C00; test_expected[3] = 16'h7C00;
        test_inputs[4] = 16'hFC00; test_expected[4] = 16'h0000;
        test_inputs[5] = 16'h7E00; test_expected[5] = 16'h7E00;

        fd = $fopen("sqrt2_log.txt", "w");

        ENABLE = 0;
        drive_io = 0;

        for (i = 0; i <= 5; i = i + 1) begin
            IO_IN = test_inputs[i];

            ENABLE = 0; #2;
            ENABLE = 1;
            drive_io = 1; #2;
            drive_io = 0;

            $fwrite(fd, "=== Тест %0d ===\n", i);
            $fwrite(fd, "На входе число: %h\n", IO_IN);
            $fwrite(fd, "Промежуточные значения:\n");

            while (!RESULT) @(posedge CLK) begin
                if (dut.loaded && dut.counter_value >= 2) begin
                    $fwrite(fd, "  Такт %0d: IO_DATA = %h, RESULT = %b, IS_NAN=%b, IS_PINF=%b, IS_NINF=%b\n",
                        dut.counter_value, dut.final_out, dut.RESULT, dut.IS_NAN, dut.IS_PINF, dut.IS_NINF);
                end
            end

            $fwrite(fd, "Результат: %h\n", dut.final_out);
            $fwrite(fd, "Ожидалось: %h\n\n\n", test_expected[i]);

            ENABLE = 0; #2;
        end

        $fclose(fd);
        $finish;
    end

endmodule
