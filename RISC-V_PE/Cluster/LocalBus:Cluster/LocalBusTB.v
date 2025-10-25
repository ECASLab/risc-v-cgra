
`include "LocalBus.v"
`timescale 1ns / 1ps

module tb_local_bus_control;

    parameter NUM_PE = 4;
    parameter WIDTH = 32;

    reg clk;
    reg reset;

    // Mock global memory interface
    reg [NUM_PE-1:0] mem_ack_global;
    reg [NUM_PE*WIDTH-1:0] mem_data_global;

    wire [NUM_PE*WIDTH-1:0] mem_address_global;
    wire [NUM_PE*WIDTH-1:0] result_out;
    wire [NUM_PE*WIDTH-1:0] mem_write_data_global;
    wire [NUM_PE-1:0] mem_write_global;
    wire [NUM_PE-1:0] mem_read_global;
    wire done;

    local_bus_control #(NUM_PE) dut (
        .clk(clk),
        .reset(reset),
        .mem_ack_global(mem_ack_global),
        .mem_data_global(mem_data_global),
        .mem_address_global(mem_address_global),
        .result_out(result_out),
        .mem_write_data_global(mem_write_data_global),
        .mem_write_global(mem_write_global),
        .mem_read_global(mem_read_global),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Starting local_bus_control testbench...");
        clk = 0;
        reset = 1;
        mem_ack_global = 0;
        mem_data_global = 0;
        #10;

        reset = 0;

        // Simulate memory ack and data responses
        mem_ack_global = 4'b1111;
        mem_data_global = {32'hAAAA0004, 32'hBBBB0003, 32'hCCCC0002, 32'hDDDD0001};
        #10;

        // Simulate another cycle with new data
        mem_data_global = {32'hAAAA0014, 32'hBBBB0013, 32'hCCCC0012, 32'hDDDD0011};
        #10;

        // Simulate completion from all PEs
        // This assumes your PE logic will eventually assert execution_complete and last_instruction
        // You may need to force these manually if PE logic is not yet implemented
        // For now, we wait and observe `done`
        repeat (10) #10;

        $display("Final done signal: %b", done);
        $display("Testbench complete.");
        $finish;
    end
endmodule
