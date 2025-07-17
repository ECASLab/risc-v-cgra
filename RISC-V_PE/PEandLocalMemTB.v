`timescale 1ns / 1ps
`include "PEandLocalMem.v"

module MemPE_tb;

  // Inputs
  reg clk;
  reg reset;
  reg grant;
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
  wire bus_request;
  wire execution_complete;
  wire branch_exec;

  // Instantiate the Device Under Test (DUT)
  MemPE uut (
    .clk(clk),
    .reset(reset),
    .grant(grant),
    .PCin(PCin),
    .instructionBus(instructionBus),
    .mem_ackBus(mem_ackBus),
    .memData(memData),
    .mem_addressBus(mem_addressBus),
    .result_outBus(result_outBus),
    .PCoutBus(PCoutBus),
    .mem_readBus(mem_readBus),
    .mem_writeBus(mem_writeBus),
    .bus_request(bus_request),
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
        $dumpfile("tb_PEMem_system.vcd");
        $dumpvars(0, MemPE_tb);

        // Monitor outputs
        $monitor("Time: %0dns | mem_addressBus: %b | result_outBus: %b | mem_writeBus: %b | mem_readBus: %b | execution_complete: %b | bus_request: %b | branch_exec: %b | PCoutBus: %b", 
                 $time, mem_addressBus, result_outBus, mem_writeBus, mem_readBus, execution_complete, bus_request, branch_exec, PCoutBus);

    $display("Starting MemPE testbench...");

    // Initialize signals
    reset = 1;
    grant = 0;
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
    instructionBus = 32'b000000000000_10100_000_00010_0000011; // Load to register 2
    PCin = 32'd1;

    #30
    grant = 1;

    #10
    grant = 0;

    #10

    #60 // waiting for mem_read signal

    grant = 1;

    #10
    grant = 0;

    #10
    memData = 32'b00000000000000001000000000000010;
    mem_ackBus = 1;

    #10
    mem_ackBus = 0;

    #40 // waiting for rdWrite

    grant = 1;

    #10
    grant = 0;

    #30

    // Initialize signals
    reset = 1;
    grant = 0;
    PCin = 0;
    instructionBus = 32'h00000000;
    mem_ackBus = 0;
    memData = 32'h00000000;

    #10;
    reset = 0;

     // Step 2: Write a 3 into reg 3
    $display ("##############################################################################");
    $display ("###################### Loading a 3 into register 3 ###########################");
    $display ("##############################################################################");
    instructionBus = 32'b000000000000_10100_000_00011_0000011; // Load to register 3
    PCin = 32'd2;

    #30
    grant = 1;

    #10
    grant = 0;

    #10

    #60 // waiting for mem_read signal

    grant = 1;

    #10
    grant = 0;

    #10
    memData = 32'b00000000000000001000000000000011;
    mem_ackBus = 1;

    #10
    mem_ackBus = 0;

    #40 // waiting for rdWrite

    grant = 1;

    #10
    grant = 0;

    #30  

    // Initialize signals
    reset = 1;
    grant = 0;
    PCin = 0;
    instructionBus = 32'h00000000;
    mem_ackBus = 0;
    memData = 32'h00000000;

    #10;
    reset = 0;

     // Step 3: Write a 4 into reg 4
    $display ("##############################################################################");
    $display ("###################### Loading a 4 into register 4 ###########################");
    $display ("##############################################################################");
    instructionBus = 32'b000000000000_10100_000_00100_0000011; // Load to register 4
    PCin = 32'd3;

    #30
    grant = 1;

    #10
    grant = 0;

    #10

    #60 // waiting for mem_read signal

    grant = 1;

    #10
    grant = 0;

    #10
    memData = 32'b00000000000000001000000000000100;
    mem_ackBus = 1;

    #10
    mem_ackBus = 0;

    #40 // waiting for rdWrite

    grant = 1;

    #10
    grant = 0;

    #30

    // Initialize signals
    reset = 1;
    grant = 0;
    PCin = 0;
    instructionBus = 32'h00000000;
    mem_ackBus = 0;
    memData = 32'h00000000;

    #10;
    reset = 0;

    // Step 4: Add registers 2 and 3
    $display ("##############################################################################");
    $display ("######################## Add registers 2 and 3 ###############################");
    $display ("##############################################################################");
    PCin = 32'h00000004; // Program counter input
    instructionBus = 32'b0000000_00011_00010_000_00101_0110011; //funct7 = 0000000, rs1 = 2, rs2 = 3, rd = 5, funct3 = 000, op = 51
        
    #30 // waiting for read_en
    grant = 1;

    #10
    grant = 0;
    //data_ReadyBus = 1;
    //AmuxBus = 32'b11111111000000000000000000100101;
    //BmuxBus = 32'b00000000000000000000000000000100;

    #10 
    //data_ReadyBus = 0;

    #70 //Waiting for rdWrite signal

    grant = 1;

    #10
    grant = 0;

    #30
    //Expected 00000000000000000000000000000101 


    $finish;
  end

endmodule
