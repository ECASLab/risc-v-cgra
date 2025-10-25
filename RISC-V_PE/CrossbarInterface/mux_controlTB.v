`include "mux_control.v"
`timescale 1ns / 1ps
`include "devs.vh"

module tb_mux_control;

    parameter N = 4;
    parameter TIMEOUT_CYCLES = 4;

    // Inputs
    reg clk;
    reg rst;
    reg [N-1:0] request;
    reg release_sig;

    // Outputs
    wire [`CLOG2(N)-1:0] select;
    wire valid;

    // DUT
    mux_control #(N, TIMEOUT_CYCLES) dut (
        .clk(clk),
        .rst(rst),
        .request(request),
        .release_sig(release_sig),
        .select(select),
        .valid(valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Starting mux_control testbench...");
        clk = 0;
        rst = 1;
        request = 0;
        release_sig = 0;
        #10;

        rst = 0;
        $display("Time after reset: %0t", $time);

        // Test 1: Cluster 1 requests and releases after 2 cycles
        request = 4'b0010;
        #10;
        $display("Cycle 1: Request = %b | Valid = %b | Select = %d", request, valid, select);
        #10;
        $display("Cycle 2: Request = %b | Valid = %b | Select = %d", request, valid, select);
        release_sig = 1;
        #10;
        $display("Cycle 3: Release = %b | Valid = %b | Select = %d", release_sig, valid, select);
        //release_sig = 0;
        $display("Time after first test: %0t", $time);

        // Test 2: Cluster 3 requests and holds beyond timeout
        request = 4'b1000;
        release_sig = 0;
        repeat (6) begin
            #10;
            $display("Cycle %0t: Request = %b | Valid = %b | Select = %d", $time, request, valid, select);
        end

        // Test 3: Cluster 0 and 2 request — verify round-robin fairness
        request = 4'b0101;
        release_sig = 1;
        #10;
        release_sig = 0;
        repeat (6) begin
            #10;
            $display("Cycle %0t: Request = %b | Valid = %b | Select = %d", $time, request, valid, select);
            release_sig = ~release_sig;
        end

        // Test 4: No requests
        request = 4'b0000;
        release_sig = 1;
        #10;
        $display("Cycle %0t: Request = %b | Valid = %b | Select = %d", $time, request, valid, select);
        #10;

        $display("Testbench complete.");
        $finish;
    end

endmodule
