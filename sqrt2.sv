module input_parser(
    input wire [15:0] value, 
    output wire [9:0] mant,
    output wire [4:0] exp,
    output wire sign,
    output wire is_zero,
    output wire is_denorm,
    output wire is_nan,
    output wire is_inf
);

    assign sign = value[15];
    assign exp  = value[14:10];
    assign mant = value[9:0];

    assign is_zero   = (exp == 0) && (mant == 0);
    assign is_denorm = (exp == 0) && (mant != 0);
    assign is_inf    = (exp == 5'b11111) && (mant == 0);
    assign is_nan    = (exp == 5'b11111) && (mant != 0);

endmodule

module special_case_handler(
    input wire [15:0] value, 
    input wire sign,
    input wire is_zero_inp,
    input wire is_nan_inp,
    input wire is_inf_inp,
    output reg [15:0] special_out,
    output wire is_nan,
    output wire is_pinf,
    output wire is_ninf,
    output wire bypass_core
);

    assign is_nan  = is_nan_inp || (is_inf_inp && sign) || (~is_zero_inp && sign);
    assign is_ninf = 1'b0;
    assign is_pinf = ~sign & is_inf_inp;

    assign bypass_core = is_zero_inp || is_nan || is_pinf;

    always @(*) begin
        if (is_nan_inp) begin
            special_out = value | 16'h7E00;
        end else if (is_nan) begin
            special_out = 16'hFE00;
        end else if (is_pinf || is_zero_inp) begin
            special_out = value;
        end else begin
            special_out = 16'h0000;
        end
    end

endmodule