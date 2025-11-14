`include "GlobalMemory.v"
`timescale 1ns / 1ps

module tb_global_memory;

    parameter NUM_PE = 4;
    parameter WIDTH = 32;
    parameter DEPTH = 256;

    reg clk;
    reg reset;
    reg [NUM_PE*WIDTH-1:0] mem_address;
    reg [NUM_PE*WIDTH-1:0] mem_write_data;
    reg [NUM_PE-1:0] mem_write;
    reg [NUM_PE-1:0] mem_read;

    wire [NUM_PE*WIDTH-1:0] mem_read_data;
    wire [NUM_PE-1:0] mem_ack;

    global_memory #(NUM_PE, DEPTH) dut (
        .clk(clk),
        .reset(reset),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .mem_read_data(mem_read_data),
        .mem_ack(mem_ack)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Starting global_memory testbench...");
        clk = 0;
        reset = 1;
        mem_address = 0;
        mem_write_data = 0;
        mem_write = 0;
        mem_read = 0;
        #10;

        reset = 0;

        // Cycle 1: Write to addresses 10, 20, 30, 40
        mem_address = {32'd40, 32'd30, 32'd20, 32'd10};
        mem_write_data = {32'hAAAA4444, 32'hBBBB3333, 32'hCCCC2222, 32'hDDDD1111};
        mem_write = 4'b1111;
        mem_read = 4'b0000;
        #10;

        // Cycle 2: Read from same addresses
        mem_write = 4'b0000;
        mem_read = 4'b1111;
        #10;

        $display("Read data: %h", mem_read_data);
        $display("Ack: %b", mem_ack);

        // Cycle 3: Read from different addresses (should be 0)
        mem_address = {32'd50, 32'd60, 32'd70, 32'd80};
        mem_read = 4'b1111;
        #10;

        $display("Read data (empty): %h", mem_read_data);
        $display("Ack: %b", mem_ack);

        // Cycle 4: Read from preloaded addresses (should be 0)
        mem_address = {32'd4, 32'd3, 32'd2, 32'd1};
        mem_read = 4'b1111;
        #10;

        $display("Read data (preloaded): %h", mem_read_data);
        $display("Ack: %b", mem_ack);

        $display("Testbench complete.");
        $finish;
    end
endmodule
