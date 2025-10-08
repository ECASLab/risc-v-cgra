// Mux 2:1 Test bench

`include "mux2_1.v"
`timescale 1ns / 1ps

module tb_mux2_1;

    // Parameters
    reg [31:0] in_1;
    reg [31:0] in_2;
    reg sel;
    wire [31:0] data_out;

    initial $dumpfile("mux2_1testbench.vcd");
    initial $dumpvars(0, tb_mux2_1);

    // Instantiate the mux2_1 module
    mux2_1 uut (
        .in_1(in_1),
        .in_2(in_2),
        .sel(sel),
        .data_out(data_out)
    );

    // Test procedure
    initial begin
        // Monitor outputs
        $monitor("Time: %0dns | in_1: %h | in_2: %h | sel: %b | data_out: %h", 
                 $time, in_1, in_2, sel, data_out);

        // Test case 1: Select in_1
        in_1 = 32'hA5A5A5A5; 
        in_2 = 32'h5A5A5A5A; 
        sel = 0; // Select in_1
        #10;

        // Test case 2: Select in_2
        in_1 = 32'hA5A5A5A5; 
        in_2 = 32'h5A5A5A5A; 
        sel = 1; // Select in_2
        #10;

        // Test case 3: Different values for inputs
        in_1 = 32'hFFFFFFFF; 
        in_2 = 32'h00000000; 
        sel = 0; // Select in_1
        #10;

        // Test case 4: Different values for inputs
        in_1 = 32'hFFFFFFFF; 
        in_2 = 32'h00000000; 
        sel = 1; // Select in_2
        #10;

        // Test case 5: Random values
        in_1 = 32'h12345678; 
        in_2 = 32'h87654321; 
        sel = 0; // Select in_1
        #10;

        // Test case 6: Random values with selection change
        sel = 1; // Select in_2
        #10;

        // Test case 7: Edge cases with zero and maximum values
        in_1 = 32'h00000000;
        in_2 = 32'hFFFFFFFF;
        
        sel = 0; // Select in_1 (should output zero)
        #10;

        sel = 1; // Select in_2 (should output maximum value)
        #10;

         $finish;
    end

endmodule