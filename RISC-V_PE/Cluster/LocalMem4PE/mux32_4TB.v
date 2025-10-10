`include "mux32_4.v"
`timescale 1ns / 1ps

module mux32_4_tb;

    // Inputs
    reg [31:0] in_1, in_2, in_3, in_4, in_5, in_6, in_7, in_8;
    reg [31:0] in_9, in_10, in_11, in_12, in_13, in_14, in_15, in_16;
    reg [31:0] in_17, in_18, in_19, in_20, in_21, in_22, in_23, in_24;
    reg [31:0] in_25, in_26, in_27, in_28, in_29, in_30, in_31, in_32;

    reg [4:0] sel0, sel1, sel2, sel3, sel4, sel5, sel6, sel7;
    reg       read_en0, read_en1, read_en2, read_en3;
    reg       reg_select0, reg_select1, reg_select2, reg_select3;

    // Outputs
    wire [31:0] data_out0, data_out1, data_out2, data_out3;
    wire [31:0] data_out4, data_out5, data_out6, data_out7;
    wire        regComplete0, regComplete1, regComplete2, regComplete3;

    // DUT
    mux32_4 dut (
        .in_1(in_1), .in_2(in_2), .in_3(in_3), .in_4(in_4),
        .in_5(in_5), .in_6(in_6), .in_7(in_7), .in_8(in_8),
        .in_9(in_9), .in_10(in_10), .in_11(in_11), .in_12(in_12),
        .in_13(in_13), .in_14(in_14), .in_15(in_15), .in_16(in_16),
        .in_17(in_17), .in_18(in_18), .in_19(in_19), .in_20(in_20),
        .in_21(in_21), .in_22(in_22), .in_23(in_23), .in_24(in_24),
        .in_25(in_25), .in_26(in_26), .in_27(in_27), .in_28(in_28),
        .in_29(in_29), .in_30(in_30), .in_31(in_31), .in_32(in_32),
        .sel0(sel0), .sel1(sel1), .sel2(sel2), .sel3(sel3),
        .sel4(sel4), .sel5(sel5), .sel6(sel6), .sel7(sel7),
        .read_en0(read_en0), .read_en1(read_en1), .read_en2(read_en2), .read_en3(read_en3),
        .reg_select0(reg_select0), .reg_select1(reg_select1), .reg_select2(reg_select2), .reg_select3(reg_select3),
        .data_out0(data_out0), .data_out1(data_out1), .data_out2(data_out2), .data_out3(data_out3),
        .data_out4(data_out4), .data_out5(data_out5), .data_out6(data_out6), .data_out7(data_out7),
        .regComplete0(regComplete0), .regComplete1(regComplete1), .regComplete2(regComplete2), .regComplete3(regComplete3)
    );

    initial begin
        $display("Starting mux32_4 test...");

        // Initialize register values
        in_1  = 32'h11111111; in_2  = 32'h22222222; in_3  = 32'h33333333; in_4  = 32'h44444444;
        in_5  = 32'h55555555; in_6  = 32'h66666666; in_7  = 32'h77777777; in_8  = 32'h88888888;
        in_9  = 32'h99999999; in_10 = 32'hAAAAAAAA; in_11 = 32'hBBBBBBBB; in_12 = 32'hCCCCCCCC;
        in_13 = 32'hDDDDDDDD; in_14 = 32'hEEEEEEEE; in_15 = 32'hFFFFFFFF; in_16 = 32'h00000000;
        in_17 = 32'h12345678; in_18 = 32'h87654321; in_19 = 32'hABCDEF01; in_20 = 32'h10FEDCBA;
        in_21 = 32'hDEADBEEF; in_22 = 32'hCAFEBABE; in_23 = 32'hFEEDFACE; in_24 = 32'hBAADF00D;
        in_25 = 32'h0BADBEEF; in_26 = 32'hFACEFEED; in_27 = 32'hC001D00D; in_28 = 32'hB16B00B5;
        in_29 = 32'h8BADF00D; in_30 = 32'hDEFEC8ED; in_31 = 32'hF00DBABE; in_32 = 32'hBADC0DE0;

        // Set selectors for each PE (2 reads per PE)
        reg_select0 = 1; //Reads both registers
        reg_select1 = 0; //Reads only one
        reg_select2 = 1; //Reads both registers
        reg_select3 = 0; //Reads only one
        sel0 = 5'd0;  // PE0 rs1
        sel1 = 5'd1;  // PE0 rs2
        sel2 = 5'd2;  // PE1 rs1
        sel3 = 5'd3;  // PE1 rs2
        sel4 = 5'd4;  // PE2 rs1
        sel5 = 5'd5;  // PE2 rs2
        sel6 = 5'd6;  // PE3 rs1
        sel7 = 5'd7;  // PE3 rs2

        read_en0 = 1;
        read_en1 = 1;
        read_en2 = 1;
        read_en3 = 1;

        #10;

        $display("Read results:");
        $display("PE0 rs1: %h", data_out0);
        $display("PE0 rs2: %h", data_out1);
        $display("PE1 rs1: %h", data_out2);
        $display("PE1 rs2: %h", data_out3);
        $display("PE2 rs1: %h", data_out4);
        $display("PE2 rs2: %h", data_out5);
        $display("PE3 rs1: %h", data_out6);
        $display("PE3 rs2: %h", data_out7);

        read_en0 = 0;

        #10;
        
        $display("Read results:");
        $display("PE0 rs1: %h", data_out0);
        $display("PE0 rs2: %h", data_out1);
        $display("PE1 rs1: %h", data_out2);
        $display("PE1 rs2: %h", data_out3);
        $display("PE2 rs1: %h", data_out4);
        $display("PE2 rs2: %h", data_out5);
        $display("PE3 rs1: %h", data_out6);
        $display("PE3 rs2: %h", data_out7);

        $finish;
    end

endmodule
