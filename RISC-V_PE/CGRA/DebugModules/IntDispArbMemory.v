`include "InterfaceDispatchArbiter.v" 
`include "../GlobalMemory.v" 

module bus_interface_memory_test_top #(
    parameter NUM_CLUSTERS = 1,
    parameter NUM_PE = 4,
    parameter INSTR_PER_CLUSTER = 4,
    parameter MEM_DEPTH = 256
)(
    input clk,
    input reset,

    // === Global Outputs ===
    output [NUM_PE-1:0] branch_exec,
    output [NUM_PE*32-1:0] result_out,
    output done
);

    // === Internal Signals ===
    wire [NUM_PE-1:0] mem_ack_global;
    wire [NUM_PE*32-1:0] mem_data_global;
    wire [NUM_PE*32-1:0] mem_address_global;
    wire [NUM_PE*32-1:0] mem_write_data_global;
    wire [NUM_PE-1:0] mem_read_global;
    wire [NUM_PE-1:0] mem_write_global;

    bus_interface_test_top #(.NUM_CLUSTERS(NUM_CLUSTERS), .NUM_PE(NUM_PE), .INSTR_PER_CLUSTER(INSTR_PER_CLUSTER)) bus_intf (
        .clk(clk),
        .reset(reset),
        .mem_ack_global(mem_ack_global),
        .mem_data_global(mem_data_global),
        .mem_address_global(mem_address_global),
        .mem_write_data_global(mem_write_data_global),
        .mem_write_global(mem_write_global),
        .mem_read_global(mem_read_global),
        .result_out(result_out),
        .branch_exec(branch_exec),
        .done(done)
    );

    // === Global Memory ===
    global_memory #(.NUM_PE(NUM_PE), .DEPTH(MEM_DEPTH)) global_mem (
        .clk(clk),
        .reset(reset),
        .mem_address(mem_address_global),
        .mem_write_data(mem_write_data_global),
        .mem_write(mem_write_global),
        .mem_read(mem_read_global),
        .mem_read_data(mem_data_global),
        .mem_ack(mem_ack_global)
    );
endmodule

