`include "ClusterArbiter.v"

`timescale 1ns / 1ps

module tb_cluster_mem_arbiter;

    parameter NUM_CLUSTERS = 4;

    reg clk;
    reg reset;
    reg [NUM_CLUSTERS-1:0] req_read;
    reg [NUM_CLUSTERS-1:0] req_write;
    reg [NUM_CLUSTERS-1:0] working;

    wire [NUM_CLUSTERS-1:0] grant_read;
    wire [NUM_CLUSTERS-1:0] grant_write;

    cluster_mem_arbiter #(.NUM_CLUSTERS(NUM_CLUSTERS)) dut (
        .clk(clk),
        .reset(reset),
        .req_read(req_read),
        .req_write(req_write),
        .working(working),
        .grant_read(grant_read),
        .grant_write(grant_write)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("arbiter_test.vcd");
        $dumpvars(0, tb_cluster_mem_arbiter);

        clk = 0;
        reset = 1;
        req_read = 0;
        req_write = 0;
        working = 0;

        #10;
        reset = 0;

        // === Cycle 1: Cluster 0 requests read ===
        req_read = 4'b0001;
        #20;
        $display("Cycle 1 at %t: grant_read = %b, grant_write = %b", $time, grant_read, grant_write);
        working = 4'b0001;
        #10;

        // === Cycle 2: Cluster 1 requests write ===
        req_read = 0;
        req_write = 4'b0010;
        #10;
        working = 4'b0000;
        #40;
        $display("Cycle 2 at %t: grant_read = %b, grant_write = %b", $time, grant_read, grant_write);
        working = 4'b0010;
        #10;

        // === Cycle 3: Cluster 2 requests read, Cluster 3 requests write ===
        req_read = 4'b0100;
        req_write = 4'b1000;
        #10;
        working = 4'b0000;
        #40;
        $display("Cycle 3 at %t: grant_read = %b, grant_write = %b", $time, grant_read, grant_write);
        working = 4'b0100;
        #10;

        // === Release bus still write request ===
        working = 0;
        req_read = 4'b0000;
        #40;
        $display("Cycle %t: grant_read = %b, grant_write = %b", $time, grant_read, grant_write);
        working = 4'b1000;
        #10;
        working = 0;

        // === Cycle 5: All clusters idle ===
        req_read = 0;
        req_write = 0;
        #40;
        $display("Cycle 5 at %t: grant_read = %b, grant_write = %b", $time, grant_read, grant_write);

        #20;
        $finish;
    end

endmodule
