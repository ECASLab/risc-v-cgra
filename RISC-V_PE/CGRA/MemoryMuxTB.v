`include "MemoryMux.v"
`timescale 1ns / 1ps

module tb_global_memory_mux;

    parameter NUM_CLUSTERS = 4;
    parameter NUM_PE = 4;

    reg clk;
    reg reset;

    reg [NUM_CLUSTERS-1:0] grant_read;
    reg [NUM_CLUSTERS-1:0] grant_write;

    reg [NUM_CLUSTERS*NUM_PE*32-1:0] mem_address_in;
    reg [NUM_CLUSTERS*NUM_PE*32-1:0] mem_write_data_in;
    reg [NUM_CLUSTERS*NUM_PE-1:0] mem_read_in;
    reg [NUM_CLUSTERS*NUM_PE-1:0] mem_write_in;

    reg [NUM_PE*32-1:0] mem_data_global;
    reg [NUM_PE-1:0] mem_ack_global;

    wire [NUM_PE*32-1:0] mem_address_global;
    wire [NUM_PE*32-1:0] mem_write_data_global;
    wire [NUM_PE-1:0] mem_read_global;
    wire [NUM_PE-1:0] mem_write_global;

    wire [NUM_CLUSTERS*NUM_PE*32-1:0] mem_data_out;
    wire [NUM_CLUSTERS*NUM_PE-1:0] mem_ack_out;

    global_memory_mux #(
        .NUM_CLUSTERS(NUM_CLUSTERS),
        .NUM_PE(NUM_PE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .grant_read(grant_read),
        .grant_write(grant_write),
        .mem_address_in(mem_address_in),
        .mem_write_data_in(mem_write_data_in),
        .mem_read_in(mem_read_in),
        .mem_write_in(mem_write_in),
        .mem_data_global(mem_data_global),
        .mem_ack_global(mem_ack_global),
        .mem_address_global(mem_address_global),
        .mem_write_data_global(mem_write_data_global),
        .mem_read_global(mem_read_global),
        .mem_write_global(mem_write_global),
        .mem_data_out(mem_data_out),
        .mem_ack_out(mem_ack_out)
    );

    initial begin
        $display("Starting global_memory_mux testbench...");

        clk = 0;
        reset = 0;

        // Default values
        grant_read = 0;
        grant_write = 0;
        mem_address_in = 0;
        mem_write_data_in = 0;
        mem_read_in = 0;
        mem_write_in = 0;
        mem_data_global = {NUM_PE{32'hDEADBEEF}};
        mem_ack_global = {NUM_PE{1'b1}};

        // === Test 1: Cluster 2 read request ===
        grant_read = 4'b0100;

        mem_address_in[2*NUM_PE*32 +: NUM_PE*32] = {
            32'h00000020, 32'h00000021, 32'h00000022, 32'h00000023
        };
        mem_read_in[2*NUM_PE +: NUM_PE] = 4'b1010;

        #10;
        $display("READ GRANT:");
        $display("  mem_address_global = %h", mem_address_global);
        $display("  mem_read_global    = %b", mem_read_global);
        $display("  mem_data_out[2]    = %h", mem_data_out[2*NUM_PE*32 +: NUM_PE*32]);
        $display("  mem_ack_out[2]     = %b", mem_ack_out[2*NUM_PE +: NUM_PE]);

        // === Test 2: Cluster 1 write request ===
        grant_read = 0;
        grant_write = 4'b0010;

        mem_address_in[1*NUM_PE*32 +: NUM_PE*32] = {
            32'h10000000, 32'h10000001, 32'h10000002, 32'h10000003
        };
        mem_write_data_in[1*NUM_PE*32 +: NUM_PE*32] = {
            32'hAAAA0000, 32'hBBBB0001, 32'hCCCC0002, 32'hDDDD0003
        };
        mem_write_in[1*NUM_PE +: NUM_PE] = 4'b1100;

        #10;
        $display("WRITE GRANT:");
        $display("  mem_address_global     = %h", mem_address_global);
        $display("  mem_write_data_global  = %h", mem_write_data_global);
        $display("  mem_write_global       = %b", mem_write_global);

        $display("Testbench complete.");
        $finish;
    end

    always #5 clk = ~clk;

endmodule
