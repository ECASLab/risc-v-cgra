`include "ClusterArbiter.v"

`timescale 1ns / 1ps

module tb_cluster_arbiter;

    // Testbench signals
    reg clk;
    reg reset;
    reg [3:0] req;         // Request signals from Clusters
    reg [3:0] working;     // Signal to indicate bus is in use
    wire [3:0] grant;      // Grant signals from arbiter

    // Instantiate the arbiter module
    cluster_mem_arbiter uut (
        .clk(clk),
        .reset(reset),
        .req(req),
        .working(working),
        .grant(grant)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock Period = 10 time units
    end

    // Testbench logic
    initial begin
        // Dump waveform for debugging
        $dumpfile("tb_cluster_arbiter.vcd");
        $dumpvars(0, tb_cluster_arbiter);

        // Monitor outputs
        $monitor("Time: %0dns | grant: %b", 
                 $time, grant);


        // Initialize signals
        reset = 1;
        req = 4'b0000; // No requests initially
        #10 reset = 0; // Release reset

        $display("Test Case 1: Single Cluster requests (Cluster 0)");
        working = 4'b0000;
        #10 req = 4'b0001; // Cluster 0 requests access
        #10 //req = 4'b0000; // Clear request
        working = 4'b0001;

        #10 req = 4'b0000;

        #20 //give time to propagate
        working = 4'b0000;
        #10
        $display ("End of first case");

        $display("Test Case 2: Multiple requests (Cluster 1 and Cluster 3)");
        #10 req = 4'b1010; // Cluster 1 and Cluster 3 request access
        #10 working = 4'b1000;
        #10 req = 4'b0000;

        #20 working = 4'b0000;
        #10
        $display("End of second case");

        $display("Test Case 3: Sequential requests");
        #10 req = 4'b0100; // Cluster 2 requests access
        #10 req = 4'b0010; // Cluster 1 requests access
        working = 4'b0100;

        #20 working = 4'b0000;
        #10 working = 4'b0010;
        #10 req = 4'b0000;
        #20 working = 4'b0000;
        #10
        $display("End of third case");

        $display("Test Case 4: All Clusters request access");
        #10 req = 4'b1111; // All Clusters request access
        #10 working = 4'b0001; //Check to see which gets granted_index

        #20 working = 4'b0000;

        $display("Test Case 5: No requests");
        #10 req = 4'b0000; // No Clusters request access

        $display("Test Case 6: Persistent request (Cluster 0 keeps requesting access)");
        #10 req = 4'b0001; // Cluster 0 requests access again
        #50 req = 4'b0000; // Clear request

        $display("Test Case 7: Cluster requests access but previous is still using bus");
        working = 4'b0001;
        #10 req = 4'b0010; // Cluster 0 requests access again
        #50 req = 4'b0000; // Clear request

        // End simulation
        #10 $finish;
    end

endmodule
