// PE Interface module with the local memory
`include "PEinterface.v"
`include "DataRegs.v"

module MemPE (
    input clk,
    input reset,
    input grant,      //Grant signal from the arbiter
    input [31:0] PCin,    //Program counter being sent to the PE
    input [31:0] instructionBus, //Instruction loaded into PE from controller
    input        mem_ackBus, //Memory acknowledgment signal coming from the global memory
    input [31:0] memData,      //Data coming from global memory
    output [31:0] mem_addressBus,  //mem_Address sent to bus for global memory
    output [31:0] result_outBus,   //result_out sent to bus
    output [31:0] PCoutBus,        //new program counter to be sent to the controller
    output       mem_readBus,      //Signal to read from global memory
    output       mem_writeBus,     //Signal to write to global memory
    output       bus_request,    //Request signal sent to the arbiter
    output       execution_complete,
    output       branch_exec       //Indicates a branch operation is complete
);

    // Internal signals
    //Connections between PEInterface module and local memory
    wire [31:0] Aop;  //Data sent to second input of Amux (local mem)
    wire [31:0] Bop;    //Data sent to second input of Bmux (local mem)
    wire dataReady;     //Signal that data is ready in local bus
    wire [4:0] rs1;        //Select data from PE to be sent to local memory
    wire [4:0] rs2;        //Select data from PE to be sent to local memory
    wire [4:0] rd;         //Select data from PE to be sent to local memory
    wire       reg_select;    //Select signal for local memory (read 1 or 2 data)
    wire       rd_write;      //Signal to write to local memory
    wire       read_en;       //Signal to read from local memory
    wire [31:0] dataStore;    //Data to be written into local memory

    //Instantiate the PE Interface
    PE_system PEInt(
        .clk(clk),
        .id(2'b00),
        .reset(reset),
        .PCin(PCin),         // Program counter coming from bus, into muxA and into controller
        .grant(grant),
        .instructionBus(instructionBus),  // Input instruction to IR   
        .AmuxBus(Aop),
        .BmuxBus(Bop),         
        .mem_ackBus(mem_ackBus),             // Memory acknowledgment signal from bus
        .data_ReadyBus(dataReady),          // Data ready signal from bus
        .memData(memData), // Data from global mem to be loaded into A mux
        .mem_addressBus(mem_addressBus), // Address for memory operations (store)
        .result_outBus(result_outBus),
        .PCoutBus(PCoutBus),
        .rs1OutBus(rs1),
        .rs2OutBus(rs2),
        .rdOutBus(rd),
        .reg_selectBus(reg_select),
        .mem_readBus(mem_readBus),
        .mem_writeBus(mem_writeBus),
        .rd_writeBus(rd_write),
        .read_enBus(read_en),
        .bus_request(bus_request),
        .execution_complete(execution_complete),
        .data_Store(dataStore),
        .branch_exec(branch_exec)
    );

    //Instantiate the interface
    register_system localMem (
        .clk(clk),
        .reset(1'b0),       //Need to check if reset signal connected together will erase memory
        .selRD(rd),
        .selRS1(rs1),
        .selRS2(rs2),
        .reg_select(reg_select),
        .data_in(dataStore),
        .rdwrite(rd_write),
        .read_en(read_en),
        .data_out1(Aop),
        .data_out2(Bop),
        .regComplete(dataReady)
    );

    //always @(posedge clk) begin
        //$display("Aop coming from local mem: %b", Aop);
        //$display("Bop coming from local mem: %b", Bop);
    //end
endmodule

