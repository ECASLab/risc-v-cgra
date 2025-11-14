`include "InstructionMemDynamic.v"
`timescale 1ns / 1ps

module tb_instruction_memory_dynamic;

    parameter NUM_PE = 4;
    parameter DEPTH = 16;
    parameter SENTINEL = 32'hFFFFFFFF;

    reg clk;
    reg reset;

    // Read interface
    reg [NUM_PE-1:0] read_enable;
    reg [NUM_PE*32-1:0] PC;
    wire [NUM_PE*32-1:0] instruction;
    wire last_instruction;

    // Write interface
    reg write_enable;
    reg [31:0] write_data;
    reg [31:0] write_address;

    instruction_memory_dynamic #(
        .NUM_PE(NUM_PE),
        .DEPTH(DEPTH),
        .SENTINEL(SENTINEL)
    ) dut (
        .clk(clk),
        .reset(reset),
        .read_enable(read_enable),
        .PC(PC),
        .instruction(instruction),
        .last_instruction(last_instruction),
        .write_enable(write_enable),
        .write_data(write_data),
        .write_address(write_address)
    );

    // Clock generation
    always #5 clk = ~clk;

    integer i;

    initial begin
        $display("Starting instruction_memory_dynamic testbench...");
        clk = 0;
        reset = 1;
        read_enable = 0;
        PC = 0;
        write_enable = 0;
        write_data = 0;
        write_address = 0;
        #10;

        reset = 0;

        // Load 8 instructions dynamically
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            write_enable = 1;
            write_address = i;
            write_data = 32'hAAAA0000 + i;

            @(posedge clk);
            write_enable = 0;
        end

        // Write sentinel
        @(posedge clk);
        write_enable = 1;
        write_address = 8;
        write_data = SENTINEL;

        // Disable write
        @(posedge clk);
        write_enable = 0;

        // Read instructions for PCs 0–3
        @(posedge clk);
        read_enable = 4'b1111;
        PC = {
            32'd3, 32'd2, 32'd1, 32'd0
        };

        @(posedge clk);
        $display("Cycle 1: Instruction = %h | Last = %b", instruction, last_instruction);

        // Read instructions for PCs 4–7
        @(posedge clk);
        PC = {
            32'd7, 32'd6, 32'd5, 32'd4
        };

        @(posedge clk);
        $display("Cycle 2: Instruction = %h | Last = %b", instruction, last_instruction);

        // Read sentinel (PC=8)
        @(posedge clk);
        PC = {
            32'd8, 32'd8, 32'd8, 32'd8
        };

        @(posedge clk);
        $display("Cycle 3: Instruction = %h | Last = %b", instruction, last_instruction);

        $display("Testbench complete.");
        $finish;
    end
endmodule
