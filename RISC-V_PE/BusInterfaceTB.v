`include "BusInterface.v"
`timescale 1ns / 1ps

module tb_bus_interface;

    // Testbench signals
    reg clk;
    reg reset;

    // Inputs from the PE
    reg [31:0] mem_addressPE;
    reg [31:0] result_inPE;
    reg [31:0] PCoutPE;
    reg [4:0] rs1OutPE;
    reg [4:0] rs2OutPE;
    reg [4:0] rdOutPE;
    reg reg_selectPE;
    reg mem_readPE;
    reg mem_writePE;
    reg rd_writePE;
    reg read_enPE;
    reg execution_completePE;

    // Outputs to the PE
    wire [31:0] AmuxPE;
    wire [31:0] BmuxPE;
    wire [31:0] memDataPE;
    wire mem_ackPE;
    wire data_ReadyPE;

    // Signals to/from the bus
    wire bus_request;
    reg grant;
    wire [31:0] mem_addressBus;
    wire [31:0] result_outBus;
    wire [31:0] PCoutBus;
    wire [4:0] rs1OutBus;
    wire [4:0] rs2OutBus;
    wire [4:0] rdOutBus;
    wire reg_selectBus;
    wire mem_readBus;
    wire mem_writeBus;
    wire rd_writeBus;
    wire read_enBus;
    wire execution_completeBus;
    reg [31:0] AmuxBus;
    reg [31:0] BmuxBus;
    reg mem_ackBus;
    reg data_ReadyBus;
    reg [31:0] memData;

    // Instantiate the bus_interface module
    bus_interface uut (
        .clk(clk),
        .reset(reset),
        .mem_addressPE(mem_addressPE),
        .result_inPE(result_inPE),
        .PCoutPE(PCoutPE),
        .rs1OutPE(rs1OutPE),
        .rs2OutPE(rs2OutPE),
        .rdOutPE(rdOutPE),
        .reg_selectPE(reg_selectPE),
        .mem_readPE(mem_readPE),
        .mem_writePE(mem_writePE),
        .rd_writePE(rd_writePE),
        .read_enPE(read_enPE),
        .AmuxPE(AmuxPE),
        .BmuxPE(BmuxPE),
        .memDataPE(memDataPE),
        .mem_ackPE(mem_ackPE),
        .data_ReadyPE(data_ReadyPE),
        .bus_request(bus_request),
        .grant(grant),
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
        .AmuxBus(AmuxBus),
        .BmuxBus(BmuxBus),
        .mem_ackBus(mem_ackBus),
        .data_ReadyBus(data_ReadyBus),
        .memData(memData),
        .execution_completeBus(execution_completeBus),
        .execution_completePE(execution_completePE)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock period = 10 time units
    end

    // Testbench logic
    initial begin
        // Dump waveform for debugging
        $dumpfile("tb_bus_interface.vcd");
        $dumpvars(0, tb_bus_interface);

        $monitor("Time: %0dns | bus_request: %b | PCout: %d | mem_address: %b | reg_select: %b | mem_read: %b | mem_write: %b | rs1: %b | rs2: %b | rd: %b | rd_Write: %b | result_out: %b | AmuxPE: %b | BmuxPE: %b | memDataPE: %b | mem_ackPE: %b | data_ReadyPE: %b", 
                 $time, bus_request, PCoutBus, mem_addressBus, reg_selectBus, mem_readBus, mem_writeBus, rs1OutBus, rs2OutBus, rdOutBus, rd_writeBus, result_outBus, AmuxPE, BmuxPE, memDataPE, mem_ackPE, data_ReadyPE);


        // Initialize signals
        reset = 1;
        grant = 0;
        mem_addressPE = 32'd0;
        result_inPE = 32'd0;
        PCoutPE = 32'd0;
        rs1OutPE = 5'd0;
        rs2OutPE = 5'd0;
        rdOutPE = 5'd0;
        reg_selectPE = 0;
        mem_readPE = 0;
        mem_writePE = 0;
        rd_writePE = 0;
        read_enPE = 0;
        mem_ackBus = 0;
        data_ReadyBus = 0;

        #10 reset = 0; // Release reset

        // Test Case 1: PE requests a global memory write
        mem_addressPE = 32'hAABBCCDD; //memory address calculated from rs1 and immValue
        result_inPE = 32'h12345678; //Data from Rs2 to write in global memory
        mem_writePE = 1; // Request memory write: Should trigger a bus_request
        //grant = 1; // Bus grants access
        #10 
        grant = 1;

        #10
        mem_writePE = 0; // Clear memory write signal
        grant = 0;

        // Test Case 2: PE requests a global memory read
        //mem_addressPE = 32'h11223344;
        //mem_readPE = 1; // Request memory read
        //grant = 1; // Bus grants access
        //mem_ackBus = 1; // Memory acknowledgment from bus
        //memData = 32'h87654321; // Data provided by global memory
        //#10 mem_readPE = 0; // Clear memory read signal
        //mem_ackBus = 0;

        // Test Case 4: PE requests to write to local memory
        //rdOutPE = 5'd10;
        //result_inPE = 32'hFACECAFE;
        //rd_writePE = 1; // Request to write to local memory
        //grant = 1; // Bus grants access
        //#10 rd_writePE = 0;

        // Test Case 5: PE requests to read from local memory
        //rs1OutPE = 5'd1;
        //rs2OutPE = 5'd2;
        //reg_selectPE = 1;
        //read_enPE = 1; // Request read enable
        //grant = 1;
        //AmuxBus = 32'hABCD1234;
        //BmuxBus = 32'hDCBA4321;
        //data_ReadyBus = 1; // Data ready signal
        //#10 read_enPE = 0;
        //reg_selectPE = 0;
        //data_ReadyBus = 0;

        // End simulation
        #20 $finish;
    end

endmodule
