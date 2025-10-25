`include "ClusterControl.v"
`timescale 1ns / 1ps


module tb_cluster_instruction_controller;

    parameter NUM_PE = 4;
    parameter WIDTH = 32;

    reg clk;
    reg reset;
    reg [NUM_PE*WIDTH-1:0] instruction;
    reg last_instruction;
    reg [NUM_PE*WIDTH-1:0] PCout;
    reg [NUM_PE-1:0] execution_complete;

    wire [NUM_PE-1:0] read_enable;
    wire [NUM_PE*WIDTH-1:0] PC;
    wire [NUM_PE*WIDTH-1:0] PCin;
    wire [NUM_PE*WIDTH-1:0] instructions;
    wire done;

    cluster_instruction_controller #(NUM_PE) dut (
        .clk(clk),
        .reset(reset),
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
        $display("Starting cluster_instruction_controller testbench...");
        clk = 0;
        reset = 1;
        instruction = 0;
        last_instruction = 0;
        PCout = 0;
        execution_complete = 0;
        #10;

        reset = 0;

        // Cycle 1: All PEs start at PC = 0
        instruction = {4{32'hDEADBEEF}};
        PCout = {4{32'd0}};
        execution_complete = 4'b0000;
        #10;

        // Cycle 2: Sequential increment
        instruction = {4{32'hCAFEBABE}};
        PCout = {32'd1, 32'd1, 32'd1, 32'd1};
        #10;

        // Cycle 3: PE2 branches to PC=5
        instruction = {4{32'hFEEDFACE}};
        PCout = {32'd2, 32'd2, 32'd5, 32'd2};
        #10;

        // Cycle 4: PE0 and PE3 complete
        execution_complete = 4'b1001;
        instruction = {4{32'hBAADF00D}};
        PCout = {32'd3, 32'd3, 32'd6, 32'd3};
        #10;

        // Cycle 5: All complete, last instruction
        execution_complete = 4'b1111;
        last_instruction = 1;
        instruction = {4{32'hFFFFFFFF}};
        PCout = {32'd4, 32'd4, 32'd7, 32'd4};
        #10;

        $display("Final done signal: %b", done);
        $display("Testbench complete.");
        $finish;
    end
endmodule
