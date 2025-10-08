// Mux 3_1 Testbench

`include "mux3_1.v"

`timescale 1ns / 1ps

module tb_mux3_1;

    // Parameters
    reg [31:0] in_1;
    reg [31:0] in_2;
    reg [31:0] in_3;
    reg [1:0] sel;
    wire [31:0] data_out;

    initial $dumpfile("mux3_1testbench.vcd");
    initial $dumpvars(0, tb_mux3_1);


    // Instantiate the mux3_1 module
    mux3_1 uut (
        .in_1(in_1),
        .in_2(in_2),
        .in_3(in_3),
        .sel(sel),
        .data_out(data_out)
    );

    // Test procedure
    initial begin
        // Monitor outputs
        $monitor("Time: %0dns | in_1: %h | in_2: %h | in_3: %h | sel: %b | data_out: %h", 
                 $time, in_1, in_2, in_3, sel, data_out);

        // Test case 1: Select in_1
        in_1 = 32'hA5A5A5A5; 
        in_2 = 32'h5A5A5A5A; 
        in_3 = 32'h12345678; 
        sel = 2'b00; // Select in_1
        #10;

        // Test case 2: Select in_2
        sel = 2'b01; // Select in_2
        #10;

        // Test case 3: Select in_3
        sel = 2'b10; // Select in_3
        #10;

        // Test case 4: Check with different values
        in_1 = 32'hFFFFFFFF; 
        in_2 = 32'h00000000; 
        in_3 = 32'hDEADBEEF; 
        
        sel = 2'b00; // Select in_1
        #10;

        sel = 2'b01; // Select in_2
        #10;

        sel = 2'b10; // Select in_3
        #10;

        // Test case 5: Edge cases with zero and maximum values
        in_1 = 32'h00000000;
        in_2 = 32'hFFFFFFFF;
        in_3 = 32'hFFFFFFFF;
        
        sel = 2'b00; // Select in_1 (should output zero)
        #10;

        sel = 2'b01; // Select in_2 (should output maximum value)
        #10;

         sel = 2'b10; // Select in_3 (should also output maximum value)
         #10;

         $finish;
    end

endmodule