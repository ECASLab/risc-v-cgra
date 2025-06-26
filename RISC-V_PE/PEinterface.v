`include "BusInterface.v"
`include "ProcessingElement.v"

module PE_system (
    input clk,
    input reset,
    input grant,      //Grant signal from the arbiter
    input [31:0] PCin,    //Program counter being sent to the PE
    input [31:0] instructionBus, //Instruction loaded into PE from controller
    input [31:0] AmuxBus,    //Data being sent to A mux
    input [31:0] BmuxBus,    //Data being sent to B mux
    input        mem_ackBus, //Memory acknowledgment signal coming from the global memory
    input        data_ReadyBus, //register read complete
    input [31:0] memData,      //Data coming from global memory
    output [31:0] mem_addressBus,  //mem_Address sent to bus for global memory
    output [31:0] result_outBus,   //result_out sent to bus
    output [31:0] PCoutBus,        //new program counter to be sent to the controller
    output [4:0] rs1OutBus,        //Select data from PE to be sent to local memory
    output [4:0] rs2OutBus,        //Select data from PE to be sent to local memory
    output [4:0] rdOutBus,         //Select data from PE to be sent to local memory
    output       reg_selectBus,    //Select signal for local memory (read 1 or 2 data)
    output       mem_readBus,      //Signal to read from global memory
    output       mem_writeBus,     //Signal to write to global memory
    output       rd_writeBus,      //Signal to write to local memory
    output       read_enBus,
    output       bus_request,    //Request signal sent to the arbiter
    output       execution_complete,
    output [31:0] data_Store,      //data_in for local memory
    output       branch_exec       //Indicates a branch operation is complete
);

    // Internal signals
    //Inputs from PE
    wire [31:0] mem_addressPE;  //mem_Address from PE for global memory
    wire [31:0] result_inPE;    //result_out from PE
    wire [31:0] PCoutPE;        //new program counter to be sent to the controller
    wire [4:0] rs1OutPE;        //Select data from PE to be sent to local memory
    wire [4:0] rs2OutPE;        //Select data from PE to be sent to local memory
    wire [4:0] rdOutPE;         //Select data from PE to be sent to local memory
    wire       reg_selectPE;    //Select signal for local memory (read 1 or 2 data)
    wire       mem_readPE;      //Signal to read from global memory
    wire       mem_writePE;     //Signal to write to global memory
    wire       rd_writePE;      //Signal to write to local memory
    wire       read_enPE;       //Signal to read from local memory
    wire       execution_completePE;
    wire       branch_execPE;

    //Outputs to the PE
    wire [31:0] AmuxPE;    //Data being sent to A mux input 2
    wire [31:0] BmuxPE;    //Data being sent to B mux input 2
    wire [31:0] memDataPE; //Data being sent to A mux input 1
    wire        mem_ackPE; //Memory acknowledgment signal into the PE
    wire        data_ReadyPE; //data_Ready signal into the PE

    //Instantiate the PE
    processing_element PE(
        .clk(clk),
        .PCin(PCin),         // Program counter coming from bus, into muxA and into controller
        .instruction(instructionBus),  // Input instruction to IR            
        .mem_ack(mem_ackPE),             // Memory acknowledgment signal from bus
        .data_Ready(data_ReadyPE),          // Data ready signal from bus
        .AmuxIn(AmuxPE),       // Data from bus to be loaded into A mux
        .BmuxIn(BmuxPE),       // Data from bus to be loaded into B mux
        .memData(memDataPE), // Data from global mem to be loaded into A mux
        .reset(reset),
        .mem_address(mem_addressPE), // Address for memory operations (store)
        .reg_select(reg_selectPE),         // Signal to select proper register to read
        .mem_read(mem_readPE),           // Memory read signal    
        .rs1Out(rs1OutPE),       // Register Address to be read
        .rs2Out(rs2OutPE),      
        .rdOut(rdOutPE),
        .rdWrite(rd_writePE),
        .mem_write(mem_writePE),
        .result_out(result_inPE),  // Output selected from output mux
        .read_en(read_enPE),            // Read enable to take data from rs1 and rs2
        .PCout(PCoutPE),
        .execution_complete(execution_completePE),
        .branch_exec(branch_execPE)
    );

    //Instantiate the interface
    bus_interface busint (
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
        .execution_completePE(execution_completePE),
        .execution_completeBus(execution_complete),
        .data_Store(data_Store),
        .branch_exec(branch_execPE),
        .branch_execBus(branch_exec)
    );
endmodule

