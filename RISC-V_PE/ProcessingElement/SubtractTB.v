`timescale 1ns / 1ps
`include "Subtraction.v"

module tb_Subtraction;

    // Inputs
    reg [31:0] A, B;

    // Outputs
    wire [31:0] Diff;
    wire Borrow;

    // Instantiate the Subtraction module
    Subtraction uut (
        .A(A),
        .B(B),
        .Diff(Diff),
        .Borrow(Borrow)
    );

    // Initialize and apply test cases
    initial begin
        // Dump waveforms for debugging
        $dumpfile("Subtraction_tb.vcd");
        $dumpvars(0, tb_Subtraction);

        $display("Starting Subtraction Test Cases");

        // Test Case 1: Simple subtraction with no borrow
        A = 32'd15; B = 32'd5; 
        #10;
        $display("TC1 | A: %d, B: %d | Diff: %d, Borrow: %b", A, B, Diff, Borrow);

        // Test Case 2: Subtraction causing a borrow
        A = 32'd5; B = 32'd15; 
        #10;
        $display("TC2 | A: %d, B: %d | Diff: %d, Borrow: %b", A, B, Diff, Borrow);

        // Test Case 3: Subtraction with zero
        A = 32'd20; B = 32'd0;
        #10;
        $display("TC3 | A: %d, B: %d | Diff: %d, Borrow: %b", A, B, Diff, Borrow);

        // Test Case 4: Subtracting identical values
        A = 32'd25; B = 32'd25;
        #10;
        $display("TC4 | A: %d, B: %d | Diff: %d, Borrow: %b", A, B, Diff, Borrow);

        // Test Case 5: Large numbers with no borrow
        A = 32'hFFFFFFF0; B = 32'h0000000F;
        #10;
        $display("TC5 | A: %h, B: %h | Diff: %h, Borrow: %b", A, B, Diff, Borrow);

        // Test Case 6: Overflow subtraction (negative result)
        A = 32'h00000001; B = 32'hFFFFFFFF;
        #10;
        $display("TC6 | A: %h, B: %h | Diff: %h, Borrow: %b", A, B, Diff, Borrow);

        // Test Case 7: Both inputs as zero
        A = 32'd0; B = 32'd0;
        #10;
        $display("TC7 | A: %d, B: %d | Diff: %d, Borrow: %b", A, B, Diff, Borrow);

        // End the simulation
        $finish;
    end

endmodule
