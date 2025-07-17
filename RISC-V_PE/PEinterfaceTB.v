`include "PEinterface.v"
`timescale 1ns / 1ps

module tb_PE_system;

    // Testbench signals
    reg clk;
    reg reset;
    reg [31:0] PCin;  //Program counter received from controller
    reg grant;      // Grant signal from arbiter
    reg [31:0] instructionBus; // Instruction loaded into the PE
    reg [31:0] AmuxBus;    // Data sent to A mux from local memory
    reg [31:0] BmuxBus;    // Data sent to B mux from local memory
    reg mem_ackBus;        // Memory acknowledgment signal from the bus
    reg data_ReadyBus;     // Register read complete signal from local memory
    reg [31:0] memData;    // Data from global memory

    // Outputs from the PE_system
    wire [31:0] mem_addressBus;  // Memory address sent to bus for global memory
    wire [31:0] result_outBus;   // Result output sent to bus
    wire [31:0] PCoutBus;        // New program counter to be sent to the controller
    wire [4:0] rs1OutBus;        // Local memory select signal for rs1
    wire [4:0] rs2OutBus;        // Local memory select signal for rs2
    wire [4:0] rdOutBus;         // Local memory select signal for rd
    wire reg_selectBus;          // Select signal for local memory read (1 or 2 data)
    wire mem_readBus;            // Signal to read from global memory
    wire mem_writeBus;           // Signal to write to global memory
    wire rd_writeBus;            // Signal to write to local memory
    wire read_enBus;             // Signal to read from local memory
    wire bus_request;            // Request signal sent to arbiter
    wire execution_complete;
    wire branch_exec;
    wire [31:0] data_Store;

    // Instantiate the PE_system
    PE_system uut (
        .clk(clk),
        .reset(reset),
        .grant(grant),
        .PCin(PCin),
        .instructionBus(instructionBus),
        .AmuxBus(AmuxBus),
        .BmuxBus(BmuxBus),
        .mem_ackBus(mem_ackBus),
        .data_ReadyBus(data_ReadyBus),
        .memData(memData),
        .mem_addressBus(mem_addressBus),
        .result_outBus(result_outBus),
        .PCoutBus(PCoutBus),
        .rs1OutBus(rs1OutBus),
        .rs2OutBus(rs2OutBus),
        .rdOutBus(rdOutBus),
        .reg_selectBus(reg_selectBus),
        .mem_readBus(mem_readBus),
        .mem_writeBus(mem_writeBus),
        .rd_writeBus(rd_writeBus),
        .read_enBus(read_enBus),
        .bus_request(bus_request),
        .execution_complete(execution_complete),
        .branch_exec(branch_exec),
        .data_Store(data_Store)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock period = 10 time units
    end

    // Testbench logic
    initial begin
        // Dump waveform for debugging
        $dumpfile("tb_PE_system.vcd");
        $dumpvars(0, tb_PE_system);

        // Monitor outputs
        $monitor("Time: %0dns | mem_addressBus: %b | result_outBus: %b | rs1OutBus: %b | rs2OutBus: %b | reg_selectBus: %b | mem_writeBus: %b | read_enBus: %b | execution_complete: %b | bus_request: %b | reg_selectBus: %b | branch_exec: %b | rdOut: %b | data_Store: %b | PCoutBus: %b", 
                 $time, mem_addressBus, result_outBus, rs1OutBus, rs2OutBus, reg_selectBus, mem_writeBus, read_enBus, execution_complete, bus_request, reg_selectBus, branch_exec, rdOutBus, data_Store, PCoutBus);

        // Initialize signals
        reset = 1;
        grant = 0;
        PCin = 0;
        instructionBus = 32'h00000000;
        AmuxBus = 32'h00000000;
        BmuxBus = 32'h00000000;
        mem_ackBus = 0;
        data_ReadyBus = 0;
        memData = 32'b0;

        #10 reset = 0; // Release reset

        // Test Case 1: Instruction Write, store
        $display ("##############################################################################");
        $display ("###################### Start of store byte case ##############################");
        $display ("##############################################################################");
        instructionBus = 32'h2BB81A3; // Load an instruction -> store byte
        PCin = 32'd1;
        data_ReadyBus = 0;

        #30
        grant = 1;

        #10
        grant = 0;

        #10
        AmuxBus = 32'b00000000000000000000000000001000;
        data_ReadyBus = 1;

        #10
        data_ReadyBus = 0;

        #50
        grant = 1;

        #10
        grant = 0;
        
        #10
        BmuxBus = 32'b10110100101101001011010011010111;
        AmuxBus = 32'b00000000000000000000000000000000;
        data_ReadyBus = 1;

        #10
        data_ReadyBus = 0;

        #60
        grant = 1;

        #10 
        grant = 0;
        //data_ReadyBus = 0;

        #50 

        /*// Initialize signals
        reset = 1;
        grant = 0;
        PCin = 0;
        instructionBus = 32'h00000000;
        AmuxBus = 32'h00000000;
        BmuxBus = 32'h00000000;
        mem_ackBus = 0;
        data_ReadyBus = 0;
        memData = 32'h00000000;

        #10 reset = 0; // Release reset

        // Test Case 2: Load operation
        $display ("##############################################################################");
        $display ("###################### Start of load byte case ##############################");
        $display ("##############################################################################");
        PCin = 32'h00000001; // Program counter input
        instructionBus = 32'b000000100011_01011_000_10111_0000011; //Immidiate = 35, rs1 = 11, rd = 23, funct3 = 001, op = 3
        data_ReadyBus = 0;
        #30 // waiting for read_en
        grant = 1;

        #10
        grant = 0;
        AmuxBus = 32'b00000000000000000000000000100101;
        data_ReadyBus = 1;
        
        #10 
        data_ReadyBus = 0;

        #60 // waiting for mem_read signal

        grant = 1;

        #10
        grant = 0;

        #10
        memData = 32'b00000000000000001000000010100101;
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
        AmuxBus = 32'h00000000;
        BmuxBus = 32'h00000000;
        mem_ackBus = 0;
        data_ReadyBus = 0;
        memData = 32'h00000000;

        #10 reset = 0; // Release reset

        // Test Case 3: ALU with immidiate value
        $display ("##############################################################################");
        $display ("###################### Start of ALU imm Add case ##############################");
        $display ("##############################################################################");
        PCin = 32'h00000002; // Program counter input
        instructionBus = 32'b000000100011_01011_000_10111_0010011; //Immidiate = 35, rs1 = 11, rd = 23, funct3 = 000, op = 19
        
        #30 // waiting for read_en
        grant = 1;

        #10
        grant = 0;
        data_ReadyBus = 1;
        AmuxBus = 32'b10100010110000001000000010100101;

        #10 
        data_ReadyBus = 0;

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
        AmuxBus = 32'h00000000;
        BmuxBus = 32'h00000000;
        mem_ackBus = 0;
        data_ReadyBus = 0;
        memData = 32'h00000000;

        #10 reset = 0; // Release reset

        // Test Case 4: ALU with register values
        $display ("##############################################################################");
        $display ("###################### Start of ALU regs Add case ##############################");
        $display ("##############################################################################");
        PCin = 32'h00000003; // Program counter input
        instructionBus = 32'b0000000_01100_01011_000_00001_0110011; //funct7 = 0000000, rs1 = 1, rs2 = 11, rd = 1, funct3 = 000, op = 51
        
        #30 // waiting for read_en
        grant = 1;

        #10
        grant = 0;
        data_ReadyBus = 1;
        AmuxBus = 32'b11111111000000000000000000100101;
        BmuxBus = 32'b00000000000000000000000000000100;

        #10 
        data_ReadyBus = 0;

        #70 //Waiting for rdWrite signal

        grant = 1;

        #10
        grant = 0;

        #30
        //Expected 11111111000000000000000000101001 
       

        // Initialize signals
        reset = 1;
        grant = 0;
        PCin = 0;
        instructionBus = 32'h00000000;
        AmuxBus = 32'h00000000;
        BmuxBus = 32'h00000000;
        mem_ackBus = 0;
        data_ReadyBus = 0;
        memData = 32'h00000000;

        #10 reset = 0; // Release reset

        // Test Case 5: Load Upper immidiate
        $display ("##############################################################################");
        $display ("###################### Start of Load Upper Immidiate ##############################");
        $display ("##############################################################################");
        PCin = 32'h00000004; // Program counter input
        instructionBus = 32'b10110010110100101110_00001_0110111; //20 bit upper imm, rd = 1,  op = 55
        
        #30 // waiting for rdWrite
        grant = 1;

        #10
        grant = 0;

        #50
        //Expected 10110010110100101110000000000000
         

        // Initialize signals
        reset = 1;
        grant = 0;
        PCin = 0;
        instructionBus = 32'h00000000;
        AmuxBus = 32'h00000000;
        BmuxBus = 32'h00000000;
        mem_ackBus = 0;
        data_ReadyBus = 0;
        memData = 32'h00000000;

        #10 reset = 0; // Release reset

        // Test Case 5: Load Upper immidiate
        $display ("##############################################################################");
        $display ("###################### Start of Branch if equal ##############################");
        $display ("##############################################################################");
        PCin = 32'd28; // Program counter input
        instructionBus = 32'b1011001_01010_10101_000_11001_1100011; //12 bit imm value, rs1 = 10101, rs2 = 01010, funct3 = 000,  op = 99
        
        #30 // waiting for read_en
        grant = 1;

        #10
        grant = 0;

        data_ReadyBus = 1;
        AmuxBus = 32'b01000001000000010000000011001000;
        BmuxBus = 32'b01000001000000010000000011001000;

        #10 
        data_ReadyBus = 0;

        #70 //Waiting for rdWrite signal

        grant = 1;

        #10
        grant = 0;

        #30
        //Expected 11111111111111111111101101010100 

        // Initialize signals
        reset = 1;
        grant = 0;
        PCin = 0;
        instructionBus = 32'h00000000;
        AmuxBus = 32'h00000000;
        BmuxBus = 32'h00000000;
        mem_ackBus = 0;
        data_ReadyBus = 0;
        memData = 32'h00000000;

        #10 reset = 0; // Release reset

        // Test Case 5: Load Upper immidiate
        $display ("##############################################################################");
        $display ("###################### Start of Jump and link ##############################");
        $display ("##############################################################################");
        PCin = 32'd30; // Program counter input
        instructionBus = 32'b10110010101010101001_11001_1101111; //20 bit imm value, rd = 11001,  op = 111
        
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
        AmuxBus = 32'h00000000;
        BmuxBus = 32'h00000000;
        mem_ackBus = 0;
        data_ReadyBus = 0;
        memData = 32'h00000000;

        #10 reset = 0; // Release reset

        // Test Case 4: ALU with register values
        $display ("##############################################################################");
        $display ("###################### Start of ALU regs Multiplication case ##############################");
        $display ("##############################################################################");
        PCin = 32'h00000007; // Program counter input
        instructionBus = 32'b0000001_01100_01011_000_00001_0110011; //funct7 = 0000001, rs1 = 1, rs2 = 11, rd = 1, funct3 = 000, op = 51
        
        #30 // waiting for read_en
        grant = 1;

        #10
        grant = 0;
        data_ReadyBus = 1;
        AmuxBus = 32'b00000000000000000000000000000010;
        BmuxBus = 32'b00000000000000000000000000000011;

        #10 
        data_ReadyBus = 0;

        #400 //Waiting for rdWrite signal

        //grant = 1;

        //#10
        //grant = 0;

        #30
        //Expected 00000000000000000000000000000110 
        */

        // End simulation
        //#50 
        $finish;
    end

endmodule
