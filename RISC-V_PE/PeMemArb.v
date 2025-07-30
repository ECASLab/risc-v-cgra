//PE with mem and arbiter

`include "PEandLocalMem.v"
`include "BusArbiter.v"

module PEMemArb (
    input clk,
    input reset,
    input [31:0] PCin,    //Program counter being sent to the PE
    input [31:0] instructionBus, //Instruction loaded into PE from controller
    input        mem_ackBus, //Memory acknowledgment signal coming from the global memory
    input [31:0] memData,      //Data coming from global memory
    output [31:0] mem_addressBus,  //mem_Address sent to bus for global memory
    output [31:0] result_outBus,   //result_out sent to bus
    output [31:0] PCoutBus,        //new program counter to be sent to the controller
    output       mem_readBus,      //Signal to read from global memory
    output       mem_writeBus,     //Signal to write to global memory
    output       execution_complete,
    output       branch_exec       //Indicates a branch operation is complete
);

    // Internal signals
    //Connections between PEMem module and arbiter
    wire       grant;    //Signal from arbiter to grant access to bus
    wire       bus_request;      //Signal to request access to bus

    parameter PE_ID = 0;

    wire [3:0] req_bus;
    wire [3:0] grant_bus;

    // Connect PE 0 signals
    assign req_bus[PE_ID] = bus_request;
    assign grant = grant_bus[PE_ID];

    bus_arbiter arbiter (
        .clk(clk),
        .reset(reset),
        .req(req_bus),
        .grant(grant_bus)
    );

    //Instantiate the PE with memory module
    MemPE memPE(
        .clk(clk),
        .reset(reset),
        .PCin(PCin),         // Program counter coming from bus, into muxA and into controller
        .grant(grant),
        .instructionBus(instructionBus),  // Input instruction to IR      
        .mem_ackBus(mem_ackBus),             // Memory acknowledgment signal from bus
        .memData(memData), // Data from global mem to be loaded into A mux
        .mem_addressBus(mem_addressBus), // Address for memory operations (store)
        .result_outBus(result_outBus),
        .PCoutBus(PCoutBus),
        .mem_readBus(mem_readBus),
        .mem_writeBus(mem_writeBus),
        .bus_request(bus_request),
        .execution_complete(execution_complete),
        .branch_exec(branch_exec)
    );

endmodule

