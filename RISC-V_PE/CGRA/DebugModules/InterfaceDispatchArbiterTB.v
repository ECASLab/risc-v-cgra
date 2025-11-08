`timescale 1ns / 1ps
`include "InterfaceDispatchArbiter.v"

module tb_bus_interface_test_top;

    parameter NUM_CLUSTERS = 1;
    parameter NUM_PE = 4;
    parameter INSTR_PER_CLUSTER = 4;

    reg clk;
    reg reset;

    wire [NUM_PE-1:0] mem_ack_global;
    wire [NUM_PE*32-1:0] mem_data_global;
    wire [NUM_PE*32-1:0] mem_address_global;
    wire [NUM_PE*32-1:0] mem_write_data_global;
    wire [NUM_PE-1:0] branch_exec;
    wire [NUM_PE*32-1:0] result_out;
    wire done;
    wire [NUM_CLUSTERS-1:0] grant_read;
    wire [NUM_CLUSTERS-1:0] grant_write;

    // Dummy memory response
    assign mem_ack_global = (|dut.mem_read_global) ? {NUM_PE{1'b1}} : {NUM_PE{1'b0}};
    assign mem_data_global = (|dut.mem_read_global) ? {NUM_PE{32'hCAFEBABE}} : {NUM_PE{32'h00000000}};

    bus_interface_test_top #(
        .NUM_CLUSTERS(NUM_CLUSTERS),
        .NUM_PE(NUM_PE),
        .INSTR_PER_CLUSTER(INSTR_PER_CLUSTER)
    ) dut (
        .clk(clk),
        .reset(reset),
        .mem_ack_global(mem_ack_global),
        .mem_data_global(mem_data_global),
        .mem_address_global(mem_address_global),
        .mem_write_data_global(mem_write_data_global),
        .branch_exec(branch_exec),
        .result_out(result_out),
        .done(done),
        .grant_read(grant_read),
        .grant_write(grant_write)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $monitor("Time: %0dns | mem_address: %h | grant_read: %b | grant_write: %b",
                 $time, mem_address_global, grant_read, grant_write);

        $display("Starting testbench for bus_interface_test_top...");
        clk = 0;
        reset = 1;
        #20;
        reset = 0;

        // Wait for program to load
        wait (dut.program_loaded);
        $display("Program loaded into cluster.");

        // Wait for memory requests and observe arbitration
        #350;

        if (done) $display("Cluster execution complete.");

        #70;
        $display("Execution complete at time %t", $time);
        $finish;
    end

endmodule
