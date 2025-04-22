`include "BusArbiter.v"
`include "ClusterControl.v"
`include "PEInterface.v"
`include "DataRegs.v"
`include "InstructionMem.v"

module local_bus_top (
    input clk,                     // Clock signal
    input reset,                   // Reset signal
    // Outputs for global memory (cluster outputs for now)
    output [31:0] global_mem_address,
    output [31:0] global_mem_write_data, //Data output from PEs to write to memory
    input [31:0] global_mem_read_data,
    input        global_mem_ack,
    output global_mem_write,
    output global_mem_read,
    output [127:0] result_out
);

    // Internal signals for the interconnections
    wire [31:0] PCsIM;            // Program counters for instruction memory
    wire [3:0] InstReadEn;         // Read enable signals for instruction memory
    wire [127:0] PCinPE;           // Program counters to PEs
    wire [127:0] PCoutPE;          // Program counters from PEs
    wire [127:0] instruction_outPE; // Instructions loaded into PEs
    wire [127:0] instruction_mem;  // Instructions from instruction memory
    wire [3:0] execution_complete; // PE execution completion flags
    wire [3:0] bus_request;        // Bus request signals from PEs
    wire [3:0] grant;              // Grant signals from arbiter to PEs
    wire [4:0] rd;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire       mem_read;
    wire       mem_write;
    wire [31:0] mem_address;
    wire       mem_ack;
    wire       rdWrite;
    wire       read_en;
    wire       reg_select;
    wire       regComplete;
    wire [31:0] data_out1;
    wire [31:0] data_out2;
    wire [31:0] data_Store;
    wire last_instruction;

    wire [31:0] result_mux;


    // Controller
    cluster_controller ctrl (
        .clk(clk),
        .reset(reset),
        .instruction_mem(instruction_mem),
        .PCsIM(PCsIM),
        .InstReadEn(InstReadEn),
        .PCinPE(PCinPE),
        .instruction_outPE(instruction_outPE),
        .PCoutPE(PCoutPE),
        .execution_complete(execution_complete),
        .last_instruction(last_instruction)
    );

    // Instruction Memory 
    instruction_memory instr_mem (
        .clk(clk),
        .reset(reset),
        .read_enable(InstReadEn),
        .PC(PCsIM),
        .instruction(instruction_mem),
        .last_instruction(last_instruction)
    );

    // Arbiter
    bus_arbiter arb (
        .clk(clk),
        .reset(reset),
        .req(bus_request),
        .grant(grant)
    );

    //Data Registers Local Memory
    register_system dataRegs (
        .selRD(rd),
        .selRS1(rs1),
        .selRS2(rs2),
        .reg_select(reg_select),
        .data_in(data_Store),
        .rdwrite(rdWrite),
        .read_en(read_en),
        .data_out1(data_out1),
        .data_out2(data_out2),
        .regComplete(regComplete)
    );

    // 4 PE Interfaces
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : pe_interface_block
            assign result_mux = (global_mem_write) ? global_mem_write_data : result_out[i*32 +: 32]; // Conditional operation

            PE_system pe_intf (
                .clk(clk),
                .reset(reset),
                .PCin(PCinPE[i*32 +: 32]),
                .instructionBus(instruction_outPE[i*32 +: 32]),
                .AmuxBus(data_out1),
                .BmuxBus(data_out2),
                .mem_ackBus(global_mem_ack),
                .data_ReadyBus(regComplete),
                .PCoutBus(PCoutPE[i*32 +: 32]),
                .execution_complete(execution_complete[i]),
                .result_outBus(result_mux),
                .rs1OutBus(rs1),
                .rs2OutBus(rs2),
                .rdOutBus(rd),
                .reg_selectBus(reg_select),
                .mem_writeBus(global_mem_write),
                .mem_readBus(global_mem_read),
                .rd_writeBus(rdWrite),
                .read_enBus(read_en),
                .bus_request(bus_request[i]),
                .grant(grant[i]),
                .data_Store(data_Store),
                .mem_addressBus(global_mem_address),
                .memData(global_mem_read_data)
            );
        end
    endgenerate

endmodule
