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
        $monitor("Time: %0dns | mem_addressBus: %b | result_outBus: %b | rs1OutBus: %b | rs2OutBus: %b | reg_selectBus: %b | mem_writeBus: %b | read_enBus: %b | execution_complete: %b | bus_request: %b | reg_selectBus: %b | branch_exec: %b", 
                 $time, mem_addressBus, result_outBus, rs1OutBus, rs2OutBus, reg_selectBus, mem_writeBus, read_enBus, execution_complete, bus_request, reg_selectBus, branch_exec);

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

        #50
        //grant = 1;

        //#10 
        //grant = 0;
        //data_ReadyBus = 0;

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
        instructionBus = 32'b000000100011_01011_001_10111_0000011; //Immidiate = 35, rs1 = 11, rd = 23, funct3 = 001, op = 3
        data_ReadyBus = 0;
        #30 // waiting for read_en
        grant = 1;

        #10
        grant = 0;
        AmuxBus = 32'b00000000000000000000000000100101;
        data_ReadyBus = 1;
        
        #50 // waiting for mem_read signal
        data_ReadyBus = 0;

        #10
        data_ReadyBus = 1;
        grant = 1;

        #20
        grant = 0;
        data_ReadyBus = 0;

        #10
        memData = 32'b00000000000000001000000010100101;
        mem_ackBus = 1;

        #10
        data_ReadyBus = 1;

        #20 // waiting for rdWrite
        grant = 1;

        #10
        grant = 0;

        #50;*/

        // Test Case 3: Memory Read Request
        //grant = 1; // Bus grants access
        //memData = 32'h87654321; // Data from memory
        //mem_ackBus = 1; // Acknowledge memory read
        //#10  // Clear memory read request
        //mem_ackBus = 0;
        //grant = 0;

        // Test Case 4: Register Read
        //AmuxBus = 32'h11111111; // Data for rs1
        //BmuxBus = 32'h22222222; // Data for rs2
        //data_ReadyBus = 1; // Data is ready
        //#10 
        //data_ReadyBus = 0;

        // Test Case 5: Bus Request
        //grant = 1; // Bus grants access
        //#10 
        //grant = 0;

        // End simulation
        //#50 
        $finish;
    end

endmodule
