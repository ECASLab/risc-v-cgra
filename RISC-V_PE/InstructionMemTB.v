`include "InstructionMem.v"
`timescale 1ns / 1ps

module tb_instruction_memory;

    reg clk;
    reg [3:0] read_enable;
    reg [31:0] pc;       // Program counter
    wire [127:0] instruction; // Fetched instructions

    // Instantiate the instruction memory
    instruction_memory uut (
        .clk(clk),
        .read_enable(read_enable),
        .PC(pc),
        .instruction(instruction)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock period = 10 time units
    end

    // Testbench logic
    initial begin

        $monitor("Time: %0dns | Instruction 1: %h | Instruction 2: %h | Instruction 3: %h | Instruction 4: %h", 
                 $time, instruction[31:0], instruction[63:32], instruction[95:64], instruction[127:96]);

        // Initialize signals
        pc = 32'b0;             // Initialize PC to 0
        read_enable = 4'b0000;   // No PEs reading initially
        #10 read_enable = 4'b1111; // Enable all PEs for reading

        // Assign program counters for the 4 PEs
        pc = 32'd0;       // PE 0: Address 0

        #10; // Allow some cycles for the memory to fetch instructions

        // Update program counters
        pc = 32'd4;       // PE 0: Address 4

        #10; // Allow some cycles for the memory to fetch instructions

        // Disable some PEs from reading
        read_enable = 4'b1010;  // Enable only PE 1 and PE 3
        #10;

        // Update program counters for enabled PEs
        pc = 32'd8;      // PE 1: Address 8

        #10; // Allow cycles for updated reads

        // Finish simulation
        #20 $finish;
    end

endmodule
