`include "Control.v"

`timescale 1ns / 1ps

module test_controller;

// Testbench signals
reg clk;
reg ALU0;
reg [6:0] op;
reg [2:0] funct3;
reg [6:0] funct7;
reg [4:0] rs1;
reg [4:0] rs2;
reg [4:0] rd;
reg [11:0] imm12;
reg [19:0] immhi;
reg ALUcomplete;
reg [31:0] PCin;
reg        mem_ack;
reg        dataReady;
reg [31:0] ALURes;
reg        decodeComplete;
reg        reset;

// Output signals
wire [31:0] PCout;
wire [4:0] ALUsel;
wire [1:0] Asel;
wire [1:0] Bsel;
wire [1:0] Osel;
wire [4:0] rdOut;
wire rdWrite;
wire Aenable;
wire Benable;
wire IRenable;
wire reg_reset;
wire mem_read;
wire mem_write;
wire [31:0] mem_address;
wire reg_select;
wire [31:0] immvalue;
wire [4:0] rs1Out;
wire [4:0] rs2Out;
wire       execution_complete;
wire       branch_exec;
wire       secondRead;

// Instantiate the controller module
controller uut (
    .clk(clk),
    .ALU0(ALU0),
    .op(op),
    .funct3(funct3),
    .funct7(funct7),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .imm12(imm12),
    .immhi(immhi),
    .ALUcomplete(ALUcomplete),
    .PCin(PCin),
    .PCout(PCout),
    .mem_ack(mem_ack),
    .ALUsel(ALUsel),
    .Asel(Asel),
    .Bsel(Bsel),
    .Osel(Osel),
    .rdOut(rdOut),
    .rdWrite(rdWrite),
    .Aenable(Aenable),
    .Benable(Benable),
    .reg_reset(reg_reset),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_address(mem_address),
    .reg_select(reg_select),
    .immvalue(immvalue),
    .dataReady(dataReady),
    .rs1Out(rs1Out),
    .rs2Out(rs2Out),
    .ALURes(ALURes),
    .IRenable(IRenable),
    .decodeComplete(decodeComplete),
    .reset(reset),
    .execution_complete(execution_complete),
    .branch_exec(branch_exec),
    .secondRead(secondRead)
);

// Generate clock signal
initial begin
    clk = 0;
    forever #5 clk = ~clk; // Clock with a period of 10 time units
end

// Initialize and apply test vectors
initial begin
    // Monitor outputs
        $monitor("Time: %0dns | PCout: %d | ALUsel: %b | Asel: %b | Bsel: %b | Osel: %b | rdOut: %b | Aenable: %b | Benable: %b | mem_read: %b | immvalue: %b | rs1Out: %b | rs2Out: %b | reg_select: %b | mem_address: %b | branch_exec: %b", 
                 $time, PCout, ALUsel, Asel, Bsel, Osel, rdOut, Aenable, Benable, mem_read, immvalue, rs1Out, rs2Out, reg_select, mem_address, branch_exec);

    // Initialize inputs
    reset = 1;

    ALU0 = 0;
    op = 7'b0000000;
    funct3 = 3'b000;
    funct7 = 7'b0000000;
    rs1 = 5'b00000;
    rs2 = 5'b00000;
    rd = 5'b00000;
    imm12 = 12'b000000000000;
    immhi = 20'b00000000000000000000;
    PCin = 32'b0;
    mem_ack = 0;
    ALUcomplete = 0;
    dataReady = 0;

    
    // Apply a test case
    reset = 0;
    op = 7'b0000011; // Load operation
    funct3 = 3'b000; // Load byte sign extended
    imm12 = 12'b100000000001; // Immediate value
    rs1 = 5'b01010; //source register
    rd = 5'b00001; // Destination register
    PCin = 1;
    mem_ack = 0; // Memory acknowledge signal starts at 0
    #10;

    dataReady = 1;
    #10;

    ALUcomplete = 1; // After some time, ALU completes operation
    #20;

    mem_ack = 1; //Memory acknowledge signal is received
    #10;

    $display ("Start of load half word");
    ALU0 = 0;
    op = 7'b0000000;
    funct3 = 3'b000;
    funct7 = 7'b0000000;
    rs1 = 5'b00000;
    rs2 = 5'b00000;
    rd = 5'b00000;
    imm12 = 12'b000000000000;
    immhi = 20'b00000000000000000000;
    PCin = 32'b0;
    mem_ack = 0;
    ALUcomplete = 0;
    dataReady = 0;

    #10;
    reset = 1;

    #10;
    reset = 0;
    op = 7'b0000011; // Load operation
    funct3 = 3'b001; // Load half word sign extended
    imm12 = 12'b100001000001; // Immediate value
    rs1 = 5'b10101; //source register
    rd = 5'b01110; // Destination register
    PCin = 2;
    mem_ack = 0; // Memory acknowledge signal starts at 0

    #10;

    dataReady = 1;
    #10;

    ALUcomplete = 1; // After some time, ALU completes operation
    #20;

    mem_ack = 1; //Memory acknowledge signal is received
    #10;

    $display ("Start of slti");

    reset = 1;
    ALU0 = 0;
    op = 7'b0000000;
    funct3 = 3'b000;
    funct7 = 7'b0000000;
    rs1 = 5'b00000;
    rs2 = 5'b00000;
    rd = 5'b00000;
    imm12 = 12'b000000000000;
    immhi = 20'b00000000000000000000;
    PCin = 32'b0;
    mem_ack = 0;
    ALUcomplete = 0;
    dataReady = 0;

    #10;
    reset = 0;
    op = 19; // ALU
    funct3 = 3'b010; // SLTI
    imm12 = 12'b011011010011; // Immediate value
    rs1 = 5'b10001; //source register
    rd = 5'b01110; // Destination register
    PCin = 3;
    mem_ack = 0; // Memory acknowledge signal starts at 0

    #20;

    dataReady = 1;
    #10;

    ALUcomplete = 1; // After some time, ALU completes operation
    #20;

    $display ("Start of XOR");

    reset = 1;
    ALU0 = 0;
    op = 7'b0000000;
    funct3 = 3'b000;
    funct7 = 7'b0000000;
    rs1 = 5'b00000;
    rs2 = 5'b00000;
    rd = 5'b00000;
    imm12 = 12'b000000000000;
    immhi = 20'b00000000000000000000;
    PCin = 32'b0;
    mem_ack = 0;
    ALUcomplete = 0;
    dataReady = 0;

    #10;
    reset = 0;
    op = 51; // ALU
    funct3 = 3'b100; // XOR
    funct7 = 7'b0000000;
    rs1 = 5'b01100; //source register
    rs2 = 5'b10011;
    rd = 5'b10100; // Destination register
    PCin = 4;

    #10;
    dataReady = 1;

    #10;
    ALUcomplete = 1;

    #20;

    $display ("Start of Load Upper Immidiate");

    reset = 1;
    ALU0 = 0;
    op = 7'b0000000;
    funct3 = 3'b000;
    funct7 = 7'b0000000;
    rs1 = 5'b00000;
    rs2 = 5'b00000;
    rd = 5'b00000;
    imm12 = 12'b000000000000;
    immhi = 20'b00000000000000000000;
    PCin = 32'b0;
    mem_ack = 0;
    ALUcomplete = 0;
    dataReady = 0;

    #10;
    reset = 0;
    op = 55; // Load upper immidiate
    immhi = 20'b10110011010100110101;
    rd = 5'b01100; // Destination register
    PCin = 5;

    #10;
    mem_ack = 1;

    #20;

    $display ("Start of store half word");

    reset = 1;
    ALU0 = 0;
    op = 7'b0000000;
    funct3 = 3'b000;
    funct7 = 7'b0000000;
    rs1 = 5'b00000;
    rs2 = 5'b00000;
    rd = 5'b00000;
    imm12 = 12'b000000000000;
    immhi = 20'b00000000000000000000;
    PCin = 32'b0;
    mem_ack = 0;
    ALUcomplete = 0;
    dataReady = 0;

    #10;
    reset = 0;
    op = 35; // store operation
    imm12 = 12'b101100001100;
    funct3 = 3'b001; //store half word
    rs1 = 5'b00011;
    rs2 = 5'b00100;
    PCin = 6;

    #10;
    dataReady = 1;

    #10;
    ALUcomplete = 1;
    dataReady = 0;
    ALURes = 32'b00000000000000000000101100001110;

    #10;
    dataReady = 1;

    #20;


    // End the simulation
    $finish;
end

endmodule
