// Test bench for the register module

`include "reg.v"
`timescale 1ns / 1ps

module tb_Register;

    // Parameters
    reg clock;
    reg r_enable;
    reg reset;
    reg [31:0] data_in;
    wire [31:0] data_out;

    initial $dumpfile("registertestbench.vcd");
    initial $dumpvars(0, tb_Register);

    // Instantiate the Register module
    Register uut (
        .clock(clock),
        .r_enable(r_enable),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    initial begin
        clock = 0;
        forever #5 clock = ~clock; // Toggle clock every 5 time units
    end

    // Test procedure
    initial begin
        // Monitor outputs
        $monitor("Time: %0dns | Reset: %b | r_enable: %b | data_in: %h | data_out: %h", 
                 $time, reset, r_enable, data_in, data_out);

        // Initialize signals
        reset = 1; // Assert reset
        r_enable = 0; 
        data_in = 32'h00000030; 
        #10;

        reset = 0; // Deassert reset
        #10;

        // Test case 1: Enable register and load data
        r_enable = 1; 
        data_in = 32'hA5A5A5A5; 
        #10;

        // Check output after loading data
        r_enable = 0; // Disable register loading
        #10;

        // Test case 2: Load new data while enabled
        r_enable = 1; 
        data_in = 32'h5A5A5A5A; 
        #10;

        // Check output after loading new data
        r_enable = 0; // Disable register loading
        #10;

        // Test case 3: Assert reset again
        reset = 1; 
        #10;

        // Check output after reset (should be zero)
        reset = 0; 
        #10;

        // Final state check with no enable and some input data
        r_enable = 0; 
        data_in = 32'h12345678; 
        #10;

         $finish;
    end

endmodule