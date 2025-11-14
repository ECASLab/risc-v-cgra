`include "demux4_32.v"
`timescale 1ns / 1ps

module demux4_32_tb;

    reg [31:0] data_in0, data_in1, data_in2, data_in3;
    reg [4:0]  sel0, sel1, sel2, sel3;
    wire [31:0] out0, out1, out2, out3, out4, out5, out6, out7, out8, out9, out10, out11, out12, out13, out14, out15, out16, out17, out18, out19, out20, out21, out22, out23, out24, out25, out26, out27, out28, out29, out30, out31;

    // DUT
    demux4_32 dut (
        .data_in0(data_in0),
        .sel0(sel0),
        .data_in1(data_in1),
        .sel1(sel1),
        .data_in2(data_in2),
        .sel2(sel2),
        .data_in3(data_in3),
        .sel3(sel3),
        .out0(out0), .out1(out1), .out2(out2), .out3(out3),
        .out4(out4), .out5(out5), .out6(out6), .out7(out7),
        .out8(out8), .out9(out9), .out10(out10), .out11(out11),
        .out12(out12), .out13(out13), .out14(out14), .out15(out15),
        .out16(out16), .out17(out17), .out18(out18), .out19(out19),
        .out20(out20), .out21(out21), .out22(out22), .out23(out23),
        .out24(out24), .out25(out25), .out26(out26), .out27(out27),
        .out28(out28), .out29(out29), .out30(out30), .out31(out31)
    );


    integer i;

    initial begin
        $display("Starting demux4_32 test...");

         // Monitor outputs
        $monitor("Time: %0dns | out0: %h | out1: %h | out2: %h | out3: %h | out4: %h | out5: %h | out6: %h | out7: %h | out8: %h | out9: %h | out10: %h | out11: %h | out12: %h | out13: %h", 
                 $time, out0, out1, out2, out3, out4, out5, out6, out7, out8, out9, out10, out11, out12, out13);


        // Initialize inputs
        data_in0 = 32'hA0000000; sel0 = 5'd0;
        data_in1 = 32'hA0000001; sel1 = 5'd2;
        data_in2 = 32'hA0000002; sel2 = 5'd4;
        data_in3 = 32'hA0000003; sel3 = 5'd6;

        #10;

        // Conflict test
        data_in0 = 32'hDEADBEEF; sel0 = 5'd10;
        data_in1 = 32'hCAFEBABE; sel1 = 5'd10;
        data_in2 = 32'h12345678; sel2 = 5'd11;
        data_in3 = 32'h87654321; sel3 = 5'd12;

        #10;

        // write other
        data_in0 = 32'hA0000010; sel0 = 5'd1;
        data_in1 = 32'hA0000020; sel1 = 5'd3;
        data_in2 = 32'hA0000030; sel2 = 5'd5;
        data_in3 = 32'hA0000040; sel3 = 5'd7;

        #10;

        $finish;
    end

endmodule
