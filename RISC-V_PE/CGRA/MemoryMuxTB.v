`include "MemoryMux.v"
`timescale 1ns / 1ps

module tb_global_memory_mux;

    parameter NUM_CLUSTERS = 4;
    parameter NUM_PE = 4;

    reg [NUM_CLUSTERS-1:0] grant;
    reg [NUM_CLUSTERS*NUM_PE*32-1:0] mem_address_in;
    reg [NUM_CLUSTERS*NUM_PE*32-1:0] mem_write_data_in;
    reg [NUM_CLUSTERS*NUM_PE-1:0] mem_read_in;
    reg [NUM_CLUSTERS*NUM_PE-1:0] mem_write_in;

    wire [NUM_PE*32-1:0] mem_address_global;
    wire [NUM_PE*32-1:0] mem_write_data_global;
    wire [NUM_PE-1:0] mem_read_global;
    wire [NUM_PE-1:0] mem_write_global;

    global_memory_mux #(
        .NUM_CLUSTERS(NUM_CLUSTERS),
        .NUM_PE(NUM_PE)
    ) dut (
        .grant(grant),
        .mem_address_in(mem_address_in),
        .mem_write_data_in(mem_write_data_in),
        .mem_read_in(mem_read_in),
        .mem_write_in(mem_write_in),
        .mem_address_global(mem_address_global),
        .mem_write_data_global(mem_write_data_global),
        .mem_read_global(mem_read_global),
        .mem_write_global(mem_write_global)
    );

    initial begin
        $display("Starting global_memory_mux testbench...");

        // Cluster 2 gets grant
        grant = 4'b0100;

        // Populate cluster 2 signals
        mem_address_in = 0;
        mem_write_data_in = 0;
        mem_read_in = 0;
        mem_write_in = 0;

        mem_address_in[2*NUM_PE*32 +: NUM_PE*32] = {
            32'h00000020, 32'h00000021, 32'h00000022, 32'h00000023
        };
        mem_write_data_in[2*NUM_PE*32 +: NUM_PE*32] = {
            32'hAAAA0000, 32'hBBBB0001, 32'hCCCC0002, 32'hDDDD0003
        };
        mem_read_in[2*NUM_PE +: NUM_PE] = 4'b1010;
        mem_write_in[2*NUM_PE +: NUM_PE] = 4'b0101;

        #10;

        $display("Global Address: %h", mem_address_global);
        $display("Global Write Data: %h", mem_write_data_global);
        $display("Global Read: %b", mem_read_global);
        $display("Global Write: %b", mem_write_global);

        $display("Testbench complete.");
        $finish;
    end
endmodule
