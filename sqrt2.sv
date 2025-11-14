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

    wire[15:0] special_out;
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

module get_exp_mant_norm(
    output wire[15:0] MANT_OUT,
    output wire[4:0] EXP_OUT,
    input wire[9:0] MANT,
    input wire[4:0] EXP
);
    wire is_exp_even = ~EXP[0];
    wire [4:0] exp_adj = (EXP - is_exp_even) >> 1;
    assign EXP_OUT = exp_adj + 5'd8;
    assign MANT_OUT = is_exp_even ? ({1'b1, MANT} << 6) : ({1'b1, MANT} << 5);
endmodule

module get_exp_mant_denorm(
    input  wire [9:0] MANT,
    output reg  [15:0] MANT_OUT,
    output reg  [4:0] EXP_OUT
);
    integer i;
    reg [4:0] shift;
    reg [10:0] mant_shifted;

    always @(*) begin
        shift = 0;

        for (i=9; i>=0; i=i-1) begin
            if (MANT[i]) begin
                shift = 9 - i;
                i = -1;
            end
        end

        if (shift[0]) shift = shift + 1;
        mant_shifted = {1'b1, MANT} << shift;

        MANT_OUT = {5'd0, mant_shifted};
        EXP_OUT = 5'd8 - (shift >> 1);
    end
endmodule

module get_exp_mant(
    input  wire [9:0] MANT,
    input  wire [4:0] EXP,
    input  wire IS_DENORM,
    output wire [15:0] MANT_OUT,
    output wire [4:0]  EXP_OUT
);
    wire [15:0] mant_norm, mant_denorm;
    wire [4:0]  exp_norm,  exp_denorm;

    get_exp_mant_norm u_norm(.MANT(MANT), .EXP(EXP), .MANT_OUT(mant_norm), .EXP_OUT(exp_norm));
    get_exp_mant_denorm u_denorm(.MANT(MANT), .MANT_OUT(mant_denorm), .EXP_OUT(exp_denorm));

    assign MANT_OUT = IS_DENORM ? mant_denorm : mant_norm;
    assign EXP_OUT  = IS_DENORM ? exp_denorm  : exp_norm;
endmodule

