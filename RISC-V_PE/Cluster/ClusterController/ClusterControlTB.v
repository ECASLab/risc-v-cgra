`include "ClusterControl.v"
`timescale 1ns / 1ps

module tb_cluster_instruction_controller;

    parameter NUM_PE = 4;

    reg clk;
    reg reset;
    reg program_loaded;
    reg [NUM_PE*32-1:0] instruction;
    reg last_instruction;
    reg [NUM_PE*32-1:0] PCout;
    reg [NUM_PE-1:0] execution_complete;

    wire [NUM_PE-1:0] read_enable;
    wire [NUM_PE*32-1:0] PC;
    wire [NUM_PE*32-1:0] PCin;
    wire [NUM_PE*32-1:0] instructions;
    wire done;

    cluster_instruction_controller #(NUM_PE) dut (
        .clk(clk),
        .reset(reset),
        .program_loaded(program_loaded),
        .read_enable(read_enable),
        .PC(PC),
        .instruction(instruction),
        .last_instruction(last_instruction),
        .PCin(PCin),
        .instructions(instructions),
        .PCout(PCout),
        .execution_complete(execution_complete),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $monitor("Time: %0dns | ReadEn: %b | PC: %h | PCin: %h | Instructions: %h | Done: %b", 
                 $time, read_enable, PC, PCin, instructions, done);

        $display("Starting cluster_instruction_controller testbench...");
        clk = 0;
        reset = 1;
        program_loaded = 0;
        instruction = 0;
        last_instruction = 0;
        PCout = 0;
        execution_complete = 0;
        #10;

        reset = 0;

        // Simulate loading phase
        #20;
        program_loaded = 1;
        $display("Program loaded signal asserted.");

        // Cycle 1: Initial dispatch
        instruction = {
            32'hAAAA0000, 32'hBBBB0001, 32'hCCCC0002, 32'hDDDD0003
        };
        execution_complete = 4'b1111;
        PCout = {
            32'd3, 32'd2, 32'd1, 32'd0
        };
        #10;

        // Cycle 2: PE1 branches to PC=10
        instruction = {
            32'hAAAA0004, 32'hBBBB0005, 32'hCCCC0006, 32'hDDDD0007
        };
        PCout = {
            32'd7, 32'd10, 32'd5, 32'd4
        };
        execution_complete = 4'b1111;
        #10;

        // Cycle 3: Continue from PC=10,11,12,13
        instruction = {
            32'hAAAA000A, 32'hBBBB000B, 32'hCCCC000C, 32'hDDDD000D
        };
        PCout = {
            32'd13, 32'd12, 32'd11, 32'd10
        };
        execution_complete = 4'b1111;
        #10;

        // Cycle 4: Sequential
        instruction = {
            32'hAAAA000E, 32'hBBBB000F, 32'hCCCC0010, 32'hDDDD0011
        };
        PCout = {
            32'd17, 32'd16, 32'd15, 32'd14
        };
        execution_complete = 4'b1111;
        last_instruction = 1;
        #30;

        $display("Final done signal: %b", done);
        $display("Testbench complete.");
        $finish;
    end
endmodule
