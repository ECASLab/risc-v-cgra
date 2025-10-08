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
    //memData = 32'hxxxxxxxx;

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

    #50 // waiting for rdWrite

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
    //memData = 32'h00000000;

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

    #0

    // Initialize signals
    reset = 1;
    grant = 0;
    PCin = 0;
    instructionBus = 32'h00000000;
    mem_ackBus = 0;
    //memData = 32'h00000000;

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

    #80 //Waiting for rdWrite signal

    grant = 1;

    #10
    grant = 0;

    #30
    //Expected 00000000000000000000000000000101 

    // Initialize signals
    reset = 1;
    grant = 0;
    PCin = 0;
    instructionBus = 32'h00000000;
    mem_ackBus = 0;
    memData = 32'h00000000;

    #10;
    reset = 0;

    // Step 5: Shift left on reg 5
    $display ("##############################################################################");
    $display ("######################## Shift Left reg 5 ###############################");
    $display ("##############################################################################");
    PCin = 32'h00000005; // Program counter input
    instructionBus = 32'b000000000001_00101_001_00110_0010011; //imm = 1, rs1 = 5, rd = 6, funct3 = 001, op = 19
        
    #30 // waiting for read_en
    grant = 1;

    #10
    grant = 0;

    #10 

    #70 //Waiting for rdWrite signal

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

    // Step 6: Load Upper immidiate to reg 7
    $display ("##############################################################################");
    $display ("###################### Start of Load Upper Immidiate ##############################");
    $display ("##############################################################################");
    PCin = 32'h00000006; // Program counter input
    instructionBus = 32'b00000000010000000001_00111_0110111; //20 bit upper imm, rd = 7,  op = 55
        
    #30 // waiting for rdWrite
    grant = 1;

    #10
    grant = 0;

    #50

    // Initialize signals
    reset = 1;
    grant = 0;
    PCin = 0;
    instructionBus = 32'h00000000;
    mem_ackBus = 0;
    memData = 32'h00000000;

    #10;
    reset = 0;

    // Step 7: Branch if not equal
    $display ("##############################################################################");
    $display ("###################### Start of Branch if not equal ##############################");
    $display ("##############################################################################");
    PCin = 32'h00000006; // Program counter input
    instructionBus = 32'b0000000_00100_00101_001_00110_1100011; //12 bit imm value, rs1 = 5, rs2 = 6, funct3 = 001,  op = 99
        
    #30 // waiting for read_en
    grant = 1;

    #10
    grant = 0;

    //data_ReadyBus = 1;
    //AmuxBus = 32'b00000000000000000000000000000100;
    //BmuxBus = 32'b00000000000000000000000000000101;

    #10 
    //data_ReadyBus = 0;

    #70 //Waiting for rdWrite signal

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

    // Step 8: Jump
    $display ("##############################################################################");
    $display ("###################### Start of Jump and link ##############################");
    $display ("##############################################################################");
    PCin = 32'd30; // Program counter input
    instructionBus = 32'b10110010101010101001_01000_1101111; //20 bit imm value, rd = 8,  op = 111
        
    #80 // waiting for branch_exec and rdWrte
    grant = 1;

    #10
    grant = 0;

    #30
    //Expected b11111111111110101001001101001000    

    // Initialize signals
    reset = 1;
    grant = 0;
    PCin = 0;
    instructionBus = 32'h00000000;
    mem_ackBus = 0;
    memData = 32'h00000000;

    #10;
    reset = 0;

    // Step 9: Store reg 6 into mem address 32
    $display ("##############################################################################");
    $display ("###################### Start of store byte case ##############################");
    $display ("##############################################################################");
    instructionBus = 32'b0000000_00110_01000_000_00010_0100011 ; // Load an instruction -> store byte
    PCin = 32'd7;

    #30
    grant = 1;

    #10
    grant = 0;

    #10
    //AmuxBus = 32'b00000000000000000000000000001000;
    //data_ReadyBus = 1;

    #10
    //data_ReadyBus = 0;

    #50
    grant = 1;

    #10
    grant = 0;
        
    #10
    //BmuxBus = 32'b00000000000000000000000000000110;
    //AmuxBus = 32'b00000000000000000000000000000000;
    //data_ReadyBus = 1;

    #10
    //data_ReadyBus = 0;

    #60
    grant = 1;

    #10 
    grant = 0;

    #50 

    // Initialize signals
    reset = 1;
    grant = 0;
    PCin = 0;
    instructionBus = 32'h00000000;
    mem_ackBus = 0;
    memData = 32'h00000000;

    #10;
    reset = 0;

    // Step 10: Branch if less than
    $display ("##############################################################################");
    $display ("###################### Start of Branch if less than ##############################");
    $display ("##############################################################################");
    PCin = 32'h00000008; // Program counter input
    instructionBus = 32'b0000000_00101_00100_100_00110_1100011; //12 bit imm value, rs1 = 4, rs2 = 5, funct3 = 100,  op = 99
        
    #30 // waiting for read_en
    grant = 1;

    #10
    grant = 0;

    //data_ReadyBus = 1;
    //AmuxBus = 32'b00000000000000000000000000000100;
    //BmuxBus = 32'b00000000000000000000000000000101;

    #10 
    //data_ReadyBus = 0;

    #70 //Waiting for rdWrite signal

    grant = 1;

    #10
    grant = 0;

    #30 

    $finish;
  end

endmodule
