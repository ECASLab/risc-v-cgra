`timescale 1ns / 1ps
`include "IntDispArbMemory.v"

module tb_bus_interface_memory_test_top;

    parameter NUM_CLUSTERS = 1;
    parameter NUM_PE = 4;
    parameter INSTR_PER_CLUSTER = 4;
    parameter MEM_DEPTH = 256;

    reg clk;
    reg reset;

    wire [NUM_PE-1:0] branch_exec;
    wire [NUM_PE*32-1:0] result_out;
    wire done;

    wire [NUM_PE-1:0] mem_ack_global;
    wire [NUM_PE*32-1:0] mem_data_global;
    wire [NUM_PE*32-1:0] mem_address_global;
    wire [NUM_PE*32-1:0] mem_write_data_global;
    wire [NUM_PE-1:0] mem_read_global;
    wire [NUM_PE-1:0] mem_write_global;

    // === DUT: Full system with memory ===
    bus_interface_memory_test_top #(
        .NUM_CLUSTERS(NUM_CLUSTERS),
        .NUM_PE(NUM_PE),
        .INSTR_PER_CLUSTER(INSTR_PER_CLUSTER),
        .MEM_DEPTH(MEM_DEPTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .branch_exec(branch_exec),
        .result_out(result_out),
        .done(done)
    );

    // === Global Memory ===
    global_memory #(
        .NUM_PE(NUM_PE),
        .DEPTH(MEM_DEPTH)
    ) global_mem (
        .clk(clk),
        .reset(reset),
        .mem_address(mem_address_global),
        .mem_write_data(mem_write_data_global),
        .mem_write(mem_write_global),
        .mem_read(mem_read_global),
        .mem_read_data(mem_data_global),
        .mem_ack(mem_ack_global)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Starting testbench for bus_interface_memory_test_top...");
        clk = 0;
        reset = 1;
        #20;
        reset = 0;

        // Wait for program to load and execute
        wait (dut.bus_intf.program_loaded);
        $display("Program loaded into cluster.");

        #500;

        if (done) $display("Cluster execution complete.");

        #50;
        $display("Execution complete at time %t", $time);
        $finish;
    end

endmodule
