`include "../../ProcessingElement/mux3_1.v"
`include "../../ProcessingElement/reg.v"

//Module combining mux and registers

module MUX_Reg (
    input clk,
    input [31:0] inRs1,
    input [31:0] inBusA,
    input [31:0] inPC,
    input [31:0] inRs2,
    input [31:0] inBusB,
    input [31:0] inImm,
    input        Aenable,
    input        Benable,
    input        reset,
    input [1:0]  Asel,
    input [1:0]  Bsel,
    output [31:0] Aout,
    output [31:0] Bout
);

    //Internal signals
    wire [31:0] Asignal;
    wire [31:0] Bsignal;

    Register regA (
        .clock(clk),
        .reset(reset),
        .r_enable(Aenable), 
        .data_in(Asignal), 
        .data_out(Aout) 
    );

    Register regB (
        .clock(clk),
        .reset(reset),
        .r_enable(Benable), 
        .data_in(Bsignal), 
        .data_out(Bout)
    );

    mux3_1 muxA (
        .in_1(inRs1),
        .in_2(inBusA),
        .in_3(inPC),
        .sel(Asel),
        .data_out(Asignal)
    );

    mux3_1 muxB (
        .in_1(inRs2),
        .in_2(inBusB),
        .in_3(inImm),
        .sel(Bsel),
        .data_out(Bsignal)
    );

    endmodule