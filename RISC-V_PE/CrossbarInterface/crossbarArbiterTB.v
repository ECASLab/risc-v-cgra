`include "crossbarArbiter.v"
`timescale 1ns / 1ps
`include "devs.vh"

module tb_arbiter_rr;

    parameter N = 4;

    // Inputs
    reg clk;
    reg rst;
    reg [N-1:0] request;

    // Outputs
    wire [`CLOG2(N)-1:0] grant;
    wire valid;

    // DUT
    arbiter #(N) dut (
        .clk(clk),
        .rst(rst),
        .request(request),
        .grant(grant),
        .valid(valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Starting round-robin arbiter testbench...");
        clk = 0;
        rst = 1;
        request = 0;
        #10;

        rst = 0;

        // Test 1: Single request from cluster 2
        request = 4'b0100;
        #10;
        $display("Request = %b | Valid = %b | Grant = %d", request, valid, grant);

        // Test 2: Multiple requests (0, 2, 3) — should rotate
        request = 4'b1101;
        repeat (6) begin
            #10;
            $display("Request = %b | Valid = %b | Grant = %d", request, valid, grant);
        end

        // Test 3: All clusters request
        request = 4'b1111;
        repeat (6) begin
            #10;
            $display("Request = %b | Valid = %b | Grant = %d", request, valid, grant);
        end

        // Test 4: No requests
        request = 4'b0000;
        #10;
        $display("Request = %b | Valid = %b | Grant = %d", request, valid, grant);

        $display("Testbench complete.");
        $finish;
    end

endmodule
