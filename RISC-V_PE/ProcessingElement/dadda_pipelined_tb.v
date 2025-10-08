`timescale 1ns/1ps

`include "HA.v"
`include "csa_dadda.v"
`include "dadda_8.v"
`include "dadda_16.v"
`include "dadda_8_pipelined.v"
`include "dadda_16_pipelined.v"

module dadda_multiplier_tb();

    // Parameters
    parameter CLK_PERIOD = 10; // 10ns clock period (100 MHz)
    parameter TEST_CASES = 100;
    parameter PIPELINE_LATENCY = 10; // Pipeline depth
    
    // Signals
    reg clk;
    reg rst;
    reg [15:0] A, B;
    wire [31:0] non_pipelined_Y;
    wire [31:0] pipelined_Y;
    
    // Test control
    integer i;
    integer error_count;
    integer test_count;
    reg [31:0] expected_results [0:TEST_CASES-1];
    reg [15:0] test_A [0:TEST_CASES-1];
    reg [15:0] test_B [0:TEST_CASES-1];
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Instantiate multipliers
    dadda_16 original_mult (.A(A), .B(B), .Y(non_pipelined_Y));
    dadda_16_pipelined pipelined_mult (.clk(clk), .rst(rst), .A(A), .B(B), .Y_reg(pipelined_Y));

    // Initialize test vectors
    initial begin
        // Random test cases
        for (i = 0; i < TEST_CASES; i = i + 1) begin
            test_A[i] = $random;
            test_B[i] = $random;
            expected_results[i] = $signed(test_A[i]) * $signed(test_B[i]);
        end
        
        // Add some edge cases
        test_A[TEST_CASES-4] = 16'h0000; test_B[TEST_CASES-4] = 16'h0000; // 0 * 0
        test_A[TEST_CASES-3] = 16'hFFFF; test_B[TEST_CASES-3] = 16'hFFFF; // -1 * -1
        test_A[TEST_CASES-2] = 16'h8000; test_B[TEST_CASES-2] = 16'h0001; // min * 1
        test_A[TEST_CASES-1] = 16'h7FFF; test_B[TEST_CASES-1] = 16'h7FFF; // max * max
        
        expected_results[TEST_CASES-4] = 0;
        expected_results[TEST_CASES-3] = 1;
        expected_results[TEST_CASES-2] = 32'hFFFF8000;
        expected_results[TEST_CASES-1] = 32'h3FFF0001;
    end
    
    // Test procedure
    initial begin
        error_count = 0;
        test_count = 0;
        rst <= 0;
        
        // Reset
        #(CLK_PERIOD*6);
        rst <= 1;

        @(posedge clk);
        
        // Run tests
        for (i = 0; i < TEST_CASES; i = i + 1) begin
            A = test_A[i];
            B = test_B[i];
            
            // Wait for pipeline to fill
            @(posedge clk);
            
            // Check results
            if (pipelined_Y !== expected_results[i]) begin
                $display("Error at test case %0d:", i);
                $display("A = %h (%0d), B = %h (%0d)", A, $signed(A), B, $signed(B));
                $display("Expected: %h (%0d)", expected_results[i], $signed(expected_results[i]));
                $display("Got:      %h (%0d)", pipelined_Y, $signed(pipelined_Y));
                error_count = error_count + 1;
            end
            
            // Verify non-pipelined matches pipelined (after latency)
            if (non_pipelined_Y !== pipelined_Y) begin
                $display("Mismatch between pipelined and non-pipelined at test case %0d:", i);
                $display("Non-pipelined: %h (%0d)", non_pipelined_Y, $signed(non_pipelined_Y));
                $display("Pipelined:     %h (%0d)", pipelined_Y, $signed(pipelined_Y));
            end
            
            test_count = test_count + 1;
        end
        
        // Summary
        $display("\nTest complete. %0d tests run, %0d errors found.", test_count, error_count);
        
        // Check if pipelined matches non-pipelined for last test case
        #(CLK_PERIOD);
        $display("\nFinal comparison:");
        $display("Non-pipelined: %h (%0d)", non_pipelined_Y, $signed(non_pipelined_Y));
        $display("Pipelined:     %h (%0d)", pipelined_Y, $signed(pipelined_Y));
        
        $finish;
    end
    
    // Monitor
    always @(posedge clk) begin
        $display("Time %0t: A=%h, B=%h, Non-pipelined=%h, Pipelined=%h", 
                $time, A, B, non_pipelined_Y, pipelined_Y);
    end
endmodule