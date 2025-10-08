// Mux 32_1 Testbench

`include "mux32_1.v"

`timescale 1ns / 1ps

module tb_mux32_1;

    // Testbench signals
    reg [31:0] in_1, in_2, in_3, in_4, in_5, in_6, in_7, in_8;
    reg [31:0] in_9, in_10, in_11, in_12, in_13, in_14, in_15, in_16;
    reg [31:0] in_17, in_18, in_19, in_20, in_21, in_22, in_23, in_24;
    reg [31:0] in_25, in_26, in_27, in_28, in_29, in_30, in_31, in_32;
    reg [4:0] selrs1, selrs2;                // 5-bit selection signal
    reg       reg_select;
    wire [31:0] data_out1, data_out2;         // Output of the mux

    // Instantiate the mux32_1 module
    mux32_1 uut (
        .in_1(in_1), .in_2(in_2), .in_3(in_3), .in_4(in_4),
        .in_5(in_5), .in_6(in_6), .in_7(in_7), .in_8(in_8),
        .in_9(in_9), .in_10(in_10), .in_11(in_11), .in_12(in_12),
        .in_13(in_13), .in_14(in_14), .in_15(in_15), .in_16(in_16),
        .in_17(in_17), .in_18(in_18), .in_19(in_19), .in_20(in_20),
        .in_21(in_21), .in_22(in_22), .in_23(in_23), .in_24(in_24),
        .in_25(in_25), .in_26(in_26), .in_27(in_27), .in_28(in_28),
        .in_29(in_29), .in_30(in_30), .in_31(in_31), .in_32(in_32),
        .selrs1(selrs1), .selrs2(selrs2), .reg_select(reg_select),
        .data_out1(data_out1), .data_out2(data_out2)
    );

    // Testbench logic
    initial begin
        // Initialize inputs
        in_1 = 32'hAAAA0001; in_2 = 32'hAAAA0002; in_3 = 32'hAAAA0003; in_4 = 32'hAAAA0004;
        in_5 = 32'hAAAA0005; in_6 = 32'hAAAA0006; in_7 = 32'hAAAA0007; in_8 = 32'hAAAA0008;
        in_9 = 32'hAAAA0009; in_10 = 32'hAAAA000A; in_11 = 32'hAAAA000B; in_12 = 32'hAAAA000C;
        in_13 = 32'hAAAA000D; in_14 = 32'hAAAA000E; in_15 = 32'hAAAA000F; in_16 = 32'hAAAA0010;
        in_17 = 32'hAAAA0011; in_18 = 32'hAAAA0012; in_19 = 32'hAAAA0013; in_20 = 32'hAAAA0014;
        in_21 = 32'hAAAA0015; in_22 = 32'hAAAA0016; in_23 = 32'hAAAA0017; in_24 = 32'hAAAA0018;
        in_25 = 32'hAAAA0019; in_26 = 32'hAAAA001A; in_27 = 32'hAAAA001B; in_28 = 32'hAAAA001C;
        in_29 = 32'hAAAA001D; in_30 = 32'hAAAA001E; in_31 = 32'hAAAA001F; in_32 = 32'hAAAA0020;

        selrs1 = 5'd0; // Start with the first input
        selrs2 = 5'd0; // Start with the first input
        reg_select = 0;

        // Apply test cases
        repeat (32) begin
            #10; // Wait for 10 time units
            reg_select = ~reg_select;
            $display("SELrs1=%d | DATA_OUT1=%h | SELrs2=%d | DATA_OUT2=%h | REG_SEL=%b", selrs1, data_out1, selrs2, data_out2, reg_select);
            selrs1 = selrs1 + 1; // Increment selection
            selrs2 = selrs2 + 1; // Increment selection
        end

        $finish; // End simulation
    end

endmodule
