`include "ClusterControl.v"
`timescale 1ns / 1ps

module tb_cluster_controller;

    // Testbench signals
    reg clk;                        // Clock signal
    reg reset;                      // Reset signal
    reg [127:0] instruction_mem;    // Instructions from instruction memory (4 instructions)
    reg [127:0] PCoutPE;            // Program counter outputs from PEs
    reg [3:0] execution_complete;
    reg last_instruction;
    wire [31:0] PCsIM;             // Program counters sent to instruction memory
    wire [3:0] InstReadEn;          // Read enable signals for instruction memory
    wire [127:0] PCinPE;            // Program counters sent to PEs
    wire [127:0] instruction_outPE; // Instructions loaded into PEs

    // Instantiate the cluster_controller
    cluster_controller uut (
        .clk(clk),
        .reset(reset),
        .instruction_mem(instruction_mem),
        .PCsIM(PCsIM),
        .InstReadEn(InstReadEn),
        .PCinPE(PCinPE),
        .instruction_outPE(instruction_outPE),
        .PCoutPE(PCoutPE),
        .execution_complete(execution_complete),
        .last_instruction(last_instruction)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock period = 10 time units
    end

    // Testbench logic
    initial begin
        // Dump waveform for debugging
        $dumpfile("tb_cluster_controller.vcd");
        $dumpvars(0, tb_cluster_controller);

        // Monitor outputs
        $monitor("Time: %0dns | PCsIM: %h | InstReadEn: %b | PCinPE: %h | instruction_outPE: %h", 
                 $time, PCsIM, InstReadEn, PCinPE, instruction_outPE);


        // Initialize signals
        reset = 1;
        instruction_mem = 128'b0;

        #10 reset = 0; // Release reset

        #10; //Give time for PCsIM and InstReadEn to load

        // Test Case 1: Initial instruction fetch
        instruction_mem = {32'h2BB81A3, 32'hC5F0B3, 32'h40C580B3, 32'h235AB83}; // 4 RISC-V instructions
        #20; // Allow time for fetch
        execution_complete = 1;

        // Test Case 2: Dependency-free instructions
        instruction_mem = {32'b00000000101001001000010110110011, 32'b00000000011100110000010000110011, 32'b00000000010000010000001010110011, 32'b00000000000100000000000110110011}; // No dependencies
        #20; // Allow time for dependency check

        // Test Case 3: Instructions with dependencies
        instruction_mem = {32'h00b002b3, 32'h00c00333, 32'h00d004b3, 32'h00e005b3}; // RAW and WAW dependencies
        last_instruction = 1;
        #20; // Allow time for processing

        // Test Case 4: Reset the controller
        reset = 1;
        #10 reset = 0;

        // End simulation
        #50 $finish;
    end

endmodule
