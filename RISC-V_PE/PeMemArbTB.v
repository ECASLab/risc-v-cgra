//Test bench for PE with mem and bus_arbiter

`timescale 1ns / 1ps
`include "PeMemArb.v"

module PEMemArb_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [31:0] PCin;
  reg [31:0] instructionBus;
  reg mem_ackBus;
  reg [31:0] memData;

  // Outputs
  wire [31:0] mem_addressBus;
  wire [31:0] result_outBus;
  wire [31:0] PCoutBus;
  wire mem_readBus;
  wire mem_writeBus;
  wire execution_complete;
  wire branch_exec;

  // Instantiate the Device Under Test (DUT)
  PEMemArb uut (
    .clk(clk),
    .reset(reset),
    .PCin(PCin),
    .instructionBus(instructionBus),
    .mem_ackBus(mem_ackBus),
    .memData(memData),
    .mem_addressBus(mem_addressBus),
    .result_outBus(result_outBus),
    .PCoutBus(PCoutBus),
    .mem_readBus(mem_readBus),
    .mem_writeBus(mem_writeBus),
    .execution_complete(execution_complete),
    .branch_exec(branch_exec)
  );

  // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock period = 10 time units
    end

  // Stimulus
  initial begin

    // Dump waveform for debugging
        $dumpfile("tb_PEMemArb_system.vcd");
        $dumpvars(0, PEMemArb_tb);

        // Monitor outputs
        $monitor("Time: %0dns | mem_addressBus: %b | result_outBus: %b | mem_writeBus: %b | mem_readBus: %b | execution_complete: %b | branch_exec: %b | PCoutBus: %b", 
                 $time, mem_addressBus, result_outBus, mem_writeBus, mem_readBus, execution_complete, branch_exec, PCoutBus);

    $display("Starting PEMemArb testbench...");

    // Initialize signals
    reset = 1;
    PCin = 0;
    instructionBus = 32'h00000000;
    mem_ackBus = 0;
    memData = 32'h00000000;

    #10;
    reset = 0;

    // Step 1: Write a 2 into reg 2
    $display ("##############################################################################");
    $display ("###################### Loading a 2 into register 2 ###########################");
    $display ("##############################################################################");
    instructionBus = 32'b000000000000_00100_000_00010_0000011; // Load to register 2
    PCin = 32'd1;

    #40

    #10
    //grant = 0;

    #10

    #80 // waiting for mem_read signal
    $display("Time right now: %dns", $time);

    //grant = 1;

    #10
    //grant = 0;

    #10 //Need to sync grant signal with mem data or store the received memData
    memData = 32'b00000000000000001000000000000010;
    mem_ackBus = 1;

    #10
    mem_ackBus = 0;

    #40 // waiting for rdWrite

    //grant = 1;

    #10
    //grant = 0;

    #30

    $finish;
  end

endmodule
