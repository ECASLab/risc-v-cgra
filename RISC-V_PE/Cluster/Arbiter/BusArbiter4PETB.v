`include "BusArbiter4PE.v"

`timescale 1ns / 1ps

module bus_arbiter4_tb;

    // Testbench signals
    reg clk;
    reg reset;
    reg [3:0] req;         // Request signals from PEs
    reg [3:0] working;     // Signal to indicate bus is in use
    wire [3:0] grant;      // Grant signals from arbiter

    // Instantiate the arbiter module
    bus_arbiter4 uut (
        .clk(clk),
        .reset(reset),
        .req(req),
        .working(working),
        .grant(grant)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Monitor outputs
        $monitor("Time: %0dns | grant: %b", 
                 $time, grant);
        
        $display("Starting bus_arbiter test...");
        clk = 0;
        reset = 1;
        req = 4'b0000;
        working = 4'b0000;

        #10 reset = 0;

        $display("Cycle 1: PE0 and PE2 request access");
        req = 4'b0101;
        #10;

        $display("Cycle 2: PE0 starts working, PE2 still requesting");
        working = 4'b0001;
        #10;

        $display("Cycle 3: PE1 and PE3 request access");
        req = 4'b1010;
        working = 4'b0000;
        #10;

        $display("Cycle 4: PE1 and PE3 granted");
        working = 4'b1010;
        #10;

        $display("Cycle 5: All PEs idle, PE0 and PE2 request again");
        req = 4'b0101;
        working = 4'b0000;
        #30;

        $finish;
    end

endmodule
