`include "MemoryInterface.v"
`timescale 1ns / 1ps

module tb_cluster_request_interface;

    parameter NUM_CLUSTERS = 4;
    parameter NUM_PE = 4;

    reg [NUM_CLUSTERS*NUM_PE-1:0] mem_read_all;
    reg [NUM_CLUSTERS*NUM_PE-1:0] mem_write_all;
    wire [NUM_CLUSTERS-1:0] req;

    cluster_request_interface #(
        .NUM_CLUSTERS(NUM_CLUSTERS),
        .NUM_PE(NUM_PE)
    ) dut (
        .mem_read_all(mem_read_all),
        .mem_write_all(mem_write_all),
        .req(req)
    );

    initial begin
        $display("Starting cluster_request_interface testbench...");

        // Cluster 0: no activity
        // Cluster 1: PE1 reads
        // Cluster 2: PE0 writes
        // Cluster 3: PE2 reads and writes

        mem_read_all = 0;
        mem_write_all = 0;

        mem_read_all[1*NUM_PE + 1] = 1; // Cluster 1, PE1
        mem_write_all[2*NUM_PE + 0] = 1; // Cluster 2, PE0
        mem_read_all[3*NUM_PE + 2] = 1;  // Cluster 3, PE2
        mem_write_all[3*NUM_PE + 2] = 1; // Cluster 3, PE2

        #10;

        $display("Request vector: %b", req); // Expect: 00001110

        $display("Testbench complete.");
        $finish;
    end
endmodule
