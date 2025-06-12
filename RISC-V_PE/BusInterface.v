module bus_interface (
    input clk,
    input reset,
    //Inputs from PE
    input [31:0] mem_addressPE,  //mem_Address from PE for global memory
    input [31:0] result_inPE,    //result_out from PE
    input [31:0] PCoutPE,        //new program counter to be sent to the controller
    input [4:0] rs1OutPE,        //Select data from PE to be sent to local memory
    input [4:0] rs2OutPE,        //Select data from PE to be sent to local memory
    input [4:0] rdOutPE,         //Select data from PE to be sent to local memory
    input       reg_selectPE,    //Select signal for local memory (read 1 or 2 data)
    input       mem_readPE,      //Signal to read from global memory
    input       mem_writePE,     //Signal to write to global memory
    input       rd_writePE,      //Signal to write to local memory
    input       read_enPE,       //Signal to read from local memory
    input       execution_completePE,

    //Outputs to the PE
    output reg [31:0] AmuxPE,    //Data being sent to A mux input 2
    output reg [31:0] BmuxPE,    //Data being sent to B mux input 2
    output reg [31:0] memDataPE, //Data being sent to A mux input 1
    output reg        mem_ackPE, //Memory acknowledgment signal into the PE
    output reg        data_ReadyPE, //data_Ready signal into the PE

    //Signals to/from the bus
    output reg bus_request,    //Request signal sent to the arbiter
    input      grant,      //Grant signal from the arbiter
    output reg [31:0] mem_addressBus,  //mem_Address sent to bus for global memory
    output reg [31:0] result_outBus,   //result_out sent to bus
    output reg [31:0] PCoutBus,        //new program counter to be sent to the controller
    output reg [4:0] rs1OutBus,        //Select data from PE to be sent to local memory
    output reg [4:0] rs2OutBus,        //Select data from PE to be sent to local memory
    output reg [4:0] rdOutBus,         //Select data from PE to be sent to local memory
    output reg       reg_selectBus,    //Select signal for local memory (read 1 or 2 data)
    output reg       mem_readBus,      //Signal to read from global memory
    output reg       mem_writeBus,     //Signal to write to global memory
    output reg       rd_writeBus,      //Signal to write to local memory
    output reg       read_enBus,
    output reg       execution_completeBus,
    output reg [31:0]  data_Store,      //data_in for local memory
    input [31:0] AmuxBus,    //Data being sent to A mux input 2
    input [31:0] BmuxBus,    //Data being sent to B mux input 2
    input [31:0] memData, //Data being sent to A mux input 1
    input        mem_ackBus, //Memory acknowledgment signal coming from the global memory
    input        data_ReadyBus //register read complete
);

    reg active; // Keep track of the bus request state
    reg currentMemRead;
    reg currentMemWrite;
    reg currentReadEn;
    reg deactivate;
    reg currentExecComplete;
    reg currentRdWrite; //Local signals to store the signal that triggered the bus request

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bus_request <= 0;
            AmuxPE <= 0;
            BmuxPE <= 0;
            memDataPE <= 0;
            mem_ackPE <= 0;
            data_ReadyPE <= 0;
            mem_addressBus <= 0;
            result_outBus <= 0;
            PCoutBus <= 0;
            rs1OutBus <= 0;
            rs2OutBus <= 0;
            rdOutBus <= 0;
            reg_selectBus <= 0;
            mem_readBus <= 0;
            mem_writeBus <= 0;
            rd_writeBus <= 0;
            read_enBus <= 0;
            active <= 0;
            execution_completeBus <= 0;
            currentMemRead <= 0;
            currentMemWrite <= 0;
            currentRdWrite <= 0;
            currentReadEn <= 0;
            currentExecComplete <= 0;
            deactivate <= 0;
        end else begin
            if ((mem_readPE || mem_writePE || rd_writePE || read_enPE || execution_completePE) && !active) begin
                $display("Signal received to request bus");
                bus_request <= 1; // Request the bus
                if (read_enPE)
                begin
                    $display ("Need to request a value from local memory");
                    currentReadEn <= 1;
                end
                else if (rd_writePE)
                begin
                    $display ("Need to write a value to local memory");
                    currentRdWrite <= 1;
                end
                else if (mem_writePE)
                begin
                    $display ("Will write a value to global memory");
                    currentMemWrite <= 1;
                end
                else if (mem_readPE)
                begin
                    $display ("Will read a value from global memory");
                    currentMemRead <= 1;
                end
                else if (execution_completePE)
                begin
                    $display ("Finished execution");
                    currentExecComplete <= 1;
                end
            end
            if (grant) begin
                $display ("Access granted");
                PCoutBus <= PCoutPE;
                if (currentMemWrite)
                begin
                    mem_addressBus <= mem_addressPE;
                    mem_writeBus <= mem_writePE;
                    result_outBus <= result_inPE;
                end
                if (currentMemRead)
                begin
                    mem_addressBus <= result_inPE; //Address is calculated from ALU
                    mem_readBus <= mem_readPE;
                end
                if (currentRdWrite)
                begin 
                    rdOutBus <= rdOutPE; //Forward select for local memory write
                    rd_writeBus <= rd_writePE;
                    data_Store <= result_inPE; //Result from ALU to be written in rd
                end
                if (currentReadEn)
                begin
                    $display ("Register address to read from");
                    rs1OutBus <= rs1OutPE;
                    rs2OutBus <= rs2OutPE;
                    read_enBus <= read_enPE;
                    reg_selectBus <= reg_selectPE;
                end
                if (currentExecComplete)
                begin
                    $display ("Execution Completed");
                    result_outBus <= result_inPE;
                    mem_addressBus <= mem_addressPE;
                    execution_completeBus <= execution_completePE;
                end
                bus_request <= 0; // Clear the request once granted
                active <= 1;
            end
            if (active) begin
                if (mem_ackBus) //Only when memRead
                begin
                    memDataPE <= memData;
                    mem_ackPE <= mem_ackBus;
                    currentMemRead <= 0;
                    bus_request <= 0;
                    deactivate <= 1;
                end
                else if (data_ReadyBus) //Only when reading local memory
                begin
                    $display ("Data from local memory is ready");
                    AmuxPE <= AmuxBus;
                    BmuxPE <= BmuxBus;
                    data_ReadyPE <= data_ReadyBus;
                    currentReadEn <= 0;
                    bus_request <= 0;
                    deactivate <= 1;
                end
                else if (execution_completePE) //Will happen at write operations 
                begin
                    result_outBus <= result_inPE;
                    mem_addressBus <= mem_addressPE;
                    execution_completeBus <= execution_completePE;
                    currentMemWrite <= 0;
                    currentRdWrite <= 0;
                    bus_request <= 0;
                    deactivate <= 1;
                end
                else if (deactivate && !data_ReadyBus && !mem_ackBus && !execution_completePE)
                begin
                    active <= 0;
                    $display("No longer active");
                    data_ReadyPE <= data_ReadyBus;
                    mem_ackPE <= mem_ackBus;
                    execution_completeBus <= execution_completePE;
                    deactivate <= 0;
                end
            end
        end
    end
endmodule
