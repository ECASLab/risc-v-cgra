`include "dataRegs4.v"
`timescale 1ns / 1ps

module register_system_tb;

    reg clk, reset;
    reg [31:0] data_in0, data_in1, data_in2, data_in3;
    reg [4:0]  selRD0, selRD1, selRD2, selRD3;
    reg        reg_select0, reg_select1, reg_select2, reg_select3;
    reg        rdwrite;

    reg [4:0]  selRS0, selRS1, selRS2, selRS3;
    reg [4:0]  selRS4, selRS5, selRS6, selRS7;
    reg        read_en;

    wire [31:0] data_out0, data_out1, data_out2, data_out3;
    wire [31:0] data_out4, data_out5, data_out6, data_out7;
    wire        regComplete;

    // DUT
    register_system dut (
        .clk(clk),
        .reset(reset),
        .data_in0(data_in0), .data_in1(data_in1), .data_in2(data_in2), .data_in3(data_in3),
        .selRD0(selRD0), .selRD1(selRD1), .selRD2(selRD2), .selRD3(selRD3),
        .rdwrite(rdwrite),
        .selRS0(selRS0), .selRS1(selRS1), .selRS2(selRS2), .selRS3(selRS3),
        .selRS4(selRS4), .selRS5(selRS5), .selRS6(selRS6), .selRS7(selRS7),
        .read_en(read_en),
        .reg_select0(reg_select0), .reg_select1(reg_select1), .reg_select2(reg_select2), .reg_select3(reg_select3), 
        .data_out0(data_out0), .data_out1(data_out1), .data_out2(data_out2), .data_out3(data_out3),
        .data_out4(data_out4), .data_out5(data_out5), .data_out6(data_out6), .data_out7(data_out7),
        .regComplete(regComplete)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Starting register_system test...");
        clk = 0;
        reset = 1;
        rdwrite = 0;
        read_en = 0;

        // Reset pulse
        #10 reset = 0;

        // Write 4 values to 4 registers
        data_in0 = 32'hAAAA0000; selRD0 = 5'd3;
        data_in1 = 32'hBBBB1111; selRD1 = 5'd7;
        data_in2 = 32'hCCCC2222; selRD2 = 5'd15;
        data_in3 = 32'hDDDD3333; selRD3 = 5'd31;
        rdwrite = 1;

        #10 rdwrite = 0;

        // Set up 8 read selectors
        reg_select0 = 1;
        reg_select1 = 1;
        reg_select2 = 0;
        reg_select3 = 1;
        selRS0 = 5'd3;   // should return AAAA0000
        selRS1 = 5'd7;   // should return BBBB1111 
        selRS2 = 5'd15;  // should return CCCC2222
        selRS3 = 5'd31;  // should return DDDD3333
        selRS4 = 5'd3;
        selRS5 = 5'd7; //Should return 0 since reg_select is 0
        selRS6 = 5'd15;
        selRS7 = 5'd31;
        read_en = 1;

        #10;

        $display("Read Results:");
        $display("data_out0: %h", data_out0);
        $display("data_out1: %h", data_out1);
        $display("data_out2: %h", data_out2);
        $display("data_out3: %h", data_out3);
        $display("data_out4: %h", data_out4);
        $display("data_out5: %h", data_out5);
        $display("data_out6: %h", data_out6);
        $display("data_out7: %h", data_out7);

        $finish;
    end

endmodule
