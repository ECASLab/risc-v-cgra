`timescale 1ns / 1ps
`include "FullAdder.v"

module tb_RippleCarryAdder;

    // Inputs
    reg [31:0] A, B;
    reg Cin;

    // Outputs
    wire [31:0] Sum;
    wire Cout;

    // Instantiate the RippleCarryAdder module
    RippleCarryAdder uut (
        .A(A),
        .B(B),
        .Cin(Cin),
        .Sum(Sum),
        .Cout(Cout)
    );

    // Initialize inputs and run test cases
    initial begin
        // Dump file for waveform analysis
        $dumpfile("RippleCarryAdder_tb.vcd");
        $dumpvars(0, tb_RippleCarryAdder);

        // Test cases
        $display("Starting Test Cases");

        // Test Case 1: Add two small numbers
        A = 32'd5; B = 32'd3; Cin = 1'b0;
        #10;
        $display("TC1 | A: %d, B: %d, Cin: %b | Sum: %d, Cout: %b", A, B, Cin, Sum, Cout);

        // Test Case 2: Add with carry in
        A = 32'd15; B = 32'd27; Cin = 1'b1;
        #10;
        $display("TC2 | A: %d, B: %d, Cin: %b | Sum: %d, Cout: %b", A, B, Cin, Sum, Cout);

        // Test Case 3: Add two large numbers
        A = 32'hFFFFFFFE; B = 32'h00000001; Cin = 1'b0;
        #10;
        $display("TC3 | A: %h, B: %h, Cin: %b | Sum: %h, Cout: %b", A, B, Cin, Sum, Cout);

        // Test Case 4: Add numbers causing overflow
        A = 32'hFFFFFFFF; B = 32'h00000001; Cin = 1'b0;
        #10;
        $display("TC4 | A: %h, B: %h, Cin: %b | Sum: %h, Cout: %b", A, B, Cin, Sum, Cout);

        // Test Case 5: Zero inputs
        A = 32'd0; B = 32'd0; Cin = 1'b0;
        #10;
        $display("TC5 | A: %d, B: %d, Cin: %b | Sum: %d, Cout: %b", A, B, Cin, Sum, Cout);

        $finish;
    end

endmodule
