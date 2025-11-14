// Test bench for the register module

`include "MUX_Reg.v"
`timescale 1ns / 1ps

module tb_MUXReg;

    // Parameters
    reg clk;
    reg [31:0] inRs1;
    reg [31:0] inBusA;
    reg [31:0] inPC;
    reg [31:0] inRs2;
    reg [31:0] inBusB;
    reg [31:0] inImm;
    reg        Aenable;
    reg        Benable;
    reg        reset;
    reg [1:0]  Asel;
    reg [1:0]  Bsel;
    wire [31:0] Aout;
    wire [31:0] Bout;

    initial $dumpfile("muxRegTestbench.vcd");
    initial $dumpvars(0, tb_MUXReg);

    // Instantiate the Register module
    MUX_Reg uut (
        .clk(clk),
        .inRs1(inRs1),
        .inBusA(inBusA),
        .inPC(inPC),
        .inRs2(inRs2),
        .inBusB(inBusB),
        .inImm(inImm),
        .Aenable(Aenable),
        .Benable(Benable),
        .reset(reset),
        .Asel(Asel),
        .Bsel(Bsel),
        .Aout(Aout),
        .Bout(Bout)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Toggle clock every 5 time units
    end

    // Test procedure
    initial begin
        // Monitor outputs
        $monitor("Time: %0dns | reset: %b | Aout: %d | Bout: %d | Aenable: %b | Benable: %b", 
                 $time, reset, Aout, Bout, Aenable, Benable);

        // Initialize signals
        reset = 1; // Assert reset
        Aenable = 0;
        Benable = 0; 
        inRs1 = 0; 
        inRs2 = 0;
        inBusA = 0;
        inBusB = 0;
        inPC = 0;
        inImm = 0;
        Asel = 0;
        Bsel = 0;
        #10;

        reset = 0; // Deassert reset
        #10;

        Asel = 2'b00; //Select rs1
        Bsel = 2'b00; //Select rs2
        inRs1 = 35;
        inRs2 = 84;
        inBusA = 22;
        inBusB = 67;
        inPC = 52;
        inImm = 12;
        #10


        // Test case 1: Enable register and load data
        Aenable = 1; 
        Benable = 1;
        #10;

        // Check output after loading data
        Aenable = 0; // Disable register loading
        Benable = 0;
        #10;

        // Test case 2: Load new data while enabled
        Aenable = 1; 
        Benable = 1;
        Asel = 2'b01; // Select data from bus
        Bsel = 2'b01; 
        #10;

        // Check output after loading new data
        Aenable = 0; // Disable register loading
        Benable = 0;
        #10;

        // Test case 3: Assert reset again
        reset = 1; 
        #10;

        // Check output after reset (should be zero)
        reset = 0; 
        #10;

        // Final state check with no enable and some input data
        Aenable = 0; 
        Benable = 0;
        Asel = 2'b10; //Select PC
        Bsel = 2'b10; //Select imm value 
        #10;

        //Enable values to see PC and imm value
        Aenable = 1;
        Benable = 1;
        #10;

        #10;
         $finish;
    end

endmodule