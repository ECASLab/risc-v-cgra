`include "InstructionMem.v"
`timescale 1ns / 1ps


module tb_instruction_memory;

    parameter NUM_PE = 4;
    parameter WIDTH = 32;

    reg clk;
    reg reset;
    reg [NUM_PE-1:0] read_enable;
    reg [NUM_PE*WIDTH-1:0] PC;
    wire [NUM_PE*WIDTH-1:0] instruction;
    wire last_instruction;

    instruction_memory #(NUM_PE) dut (
        .clk(clk),
        .reset(reset),
        .read_enable(read_enable),
        .PC(PC),
        .instruction(instruction),
        .last_instruction(last_instruction)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Starting instruction memory testbench...");
        clk = 0;
        reset = 1;
        read_enable = 0;
        PC = 0;
        #10;

        reset = 0;

        // Test 1: All PEs read from PC = 0, 1, 2, 3
        read_enable = 4'b1111;
        PC = {32'd3, 32'd2, 32'd1, 32'd0}; // PE3=3, PE2=2, PE1=1, PE0=0
        #10;

        // Test 2: Only PE1 and PE3 read
        read_enable = 4'b1010;
        PC = {32'd4, 32'd0, 32'd1, 32'd2}; // PE3=4, PE2=0, PE1=1, PE0=2
        #10;

        // Test 3: All read PC = 4 (last instruction)
        read_enable = 4'b1111;
        PC = {4{32'd4}};
        #10;

        // Test 4: No read
        read_enable = 4'b0000;
        #10;

        $display("Testbench complete.");
        $finish;
    end
endmodule
