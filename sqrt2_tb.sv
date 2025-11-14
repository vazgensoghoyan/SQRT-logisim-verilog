`timescale 1ns/1ps
`include "sqrt2.sv"

module sqrt2_tb;

    reg CLK;
    reg ENABLE;
    reg [15:0] IO_IN;       // данные для подачи на inout
    wire [15:0] IO_DATA;    // inout шина
    wire IS_NAN, IS_PINF, IS_NINF, RESULT;

    // inout управление: только первый такт ENABLE=1 шина принимает вход
    reg drive_io;
    assign IO_DATA = drive_io ? IO_IN : 16'hZZZZ;

    // Подключение DUT
    sqrt2 dut (
        .IO_DATA(IO_DATA),
        .IS_NAN(IS_NAN),
        .IS_PINF(IS_PINF),
        .IS_NINF(IS_NINF),
        .RESULT(RESULT),
        .CLK(CLK),
        .ENABLE(ENABLE)
    );

    // Лог-файл
    integer fd;

    // Тактирование
    initial CLK = 0;
    always #1 CLK = ~CLK; // период 2нс

    initial begin
        fd = $fopen("sqrt2_log.csv", "w");
        $fwrite(fd, "time,IO_DATA,IS_NAN,IS_PINF,IS_NINF,RESULT\n");

        // --- Сценарий 0 ---
        ENABLE = 0;
        IO_IN = 16'h0000; // 0
        drive_io = 0;

        #2;
        ENABLE = 1;
        IO_IN = 16'h3C00; // 1.0
        drive_io = 1;      // первый такт подачи данных
        #2;
        drive_io = 0;      // дальше ставим Z

        // ждем окончания вычисления (~11 тактов)
        #30;

		/*
        // --- Сценарий 1 ---
        ENABLE = 0; #2;
        IO_IN = 16'h4000; // 2.0
        ENABLE = 1;
        drive_io = 1;      // первый такт
        #2;
        drive_io = 0;

        #30;

        // --- Сценарий 2: +Inf ---
        ENABLE = 0; #2;
        IO_IN = 16'h7C00;
        ENABLE = 1;
        drive_io = 1; #2;
        drive_io = 0;

        #10;

        // --- Сценарий 3: NaN ---
        ENABLE = 0; #2;
        IO_IN = 16'h7E00;
        ENABLE = 1;
        drive_io = 1; #2;
        drive_io = 0;

        #10;*/

        ENABLE = 0; #2; // сброс
        $fclose(fd);
        $finish;
    end

    // Логирование на каждом фронте CLK
    always @(posedge CLK) begin
        $fwrite(fd, "%0d,%h,%b,%b,%b,%b\n",
            $time, IO_DATA, IS_NAN, IS_PINF, IS_NINF, RESULT);
    end

endmodule
