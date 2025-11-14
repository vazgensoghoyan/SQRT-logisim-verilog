module sqrt2(
    inout   wire[15:0] IO_DATA,
    output  wire IS_NAN,
    output  wire IS_PINF,
    output  wire IS_NINF,
    output  wire RESULT,
    input   wire CLK,
    input   wire ENABLE
); 
    
    // считываем входные данные на первом такте
    reg [15:0] given_input;
    reg loaded = 0;

    always @(posedge CLK) begin
        if (!ENABLE) begin
            loaded <= 0;
        end if (ENABLE && !loaded) begin
            given_input <= IO_DATA;
            loaded <= 1;
        end
    end

    // счетчик
    wire[7:0] counter_value;
    counter _counter(counter_value, CLK, ENABLE);

    // первичная обработка
    wire[9:0] mant;
    wire[4:0] exp;
    wire sign;
    wire is_input_zero, is_input_denorm, is_input_nan, is_input_inf;

    input_parser _ip(
        mant, exp, sign, is_input_zero, is_input_denorm, 
        is_input_nan, is_input_inf, given_input
    );

    reg[15:0] special_out;
    wire is_nan, is_pinf, is_ninf, bypass_core;

    special_case_handler _sch(
        special_out, is_nan, is_pinf, is_ninf, bypass_core, 
        given_input, sign, is_input_zero, is_input_nan, is_input_inf
    );

    // со второго такта выводим результат
    assign IO_DATA = (loaded && counter_value >= 2) ? special_out : 16'hZZZZ;
    assign IS_NAN = is_nan && counter_value >= 2;
    assign IS_PINF = is_pinf && counter_value >= 2;
    assign IS_NINF = is_ninf && counter_value >= 2;

    assign RESULT = bypass_core;

endmodule

module input_parser(
    output wire[9:0] MANT,
    output wire[4:0] EXP,
    output wire SIGN, 
    output wire IS_ZERO, 
    output wire IS_DENORM, 
    output wire IS_NAN, 
    output wire IS_INF,
    input wire[15:0] NUM
);

    assign SIGN = NUM[15];
    assign EXP  = NUM[14:10];
    assign MANT = NUM[9:0];

    assign IS_ZERO   = (EXP == 0) && (MANT == 0);
    assign IS_DENORM = (EXP == 0) && (MANT != 0);
    assign IS_INF    = (EXP == 5'b11111) && (MANT == 0);
    assign IS_NAN    = (EXP == 5'b11111) && (MANT != 0);

endmodule

module special_case_handler(
    output reg[15:0] SPECIAL_OUT,
    output wire IS_NAN,
    output wire IS_PINF,
    output wire IS_NINF,
    output wire BYPASS_CORE,
    input  wire[15:0] VALUE,
    input  wire SIGN,
    input  wire IS_ZERO_INP,
    input  wire IS_NAN_INP,
    input  wire IS_INF_INP
);

    assign IS_NAN  = IS_NAN_INP || (IS_INF_INP && SIGN) || (~IS_ZERO_INP && SIGN);
    assign IS_NINF = 1'b0;
    assign IS_PINF = ~SIGN & IS_INF_INP;

    assign BYPASS_CORE = IS_ZERO_INP || IS_NAN || IS_PINF;

    always @(*) begin
        if (IS_NAN_INP) begin
            SPECIAL_OUT = VALUE | 16'h7E00;  // утихомириваем NaN
        end else if (IS_NAN) begin
            SPECIAL_OUT = 16'hFE00;          // qNaN
        end else if (IS_PINF || IS_ZERO_INP) begin
            SPECIAL_OUT = VALUE;             // +Inf или 0
        end else begin
            SPECIAL_OUT = 16'h0000;          // не спец случай
        end
    end

endmodule

module counter(output reg[7:0] OUT, input CLK, ENABLE);
  always @(posedge CLK) begin
    if (ENABLE) begin
        OUT <= OUT + 1; 
    end else begin
      OUT <= 0;
    end
  end
endmodule
