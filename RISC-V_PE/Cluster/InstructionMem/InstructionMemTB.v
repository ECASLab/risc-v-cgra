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
        PC = 128'b00000000000000000000000000000011_00000000000000000000000000000010_00000000000000000000000000000001_00000000000000000000000000000000; // PE0=0
        #10;
        read_enable = 4'b0000;

        // Test 2: Read the next 4 instructions
        read_enable = 4'b1111;
        PC = 128'b00000000000000000000000000000111_00000000000000000000000000000110_00000000000000000000000000000101_00000000000000000000000000000100; // PE0=0
        #10;

        $display("Testbench complete.");
        $finish;
    end
endmodule
