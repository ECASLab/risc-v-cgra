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
    input       branch_exec,
    input [2:0] secondRead,

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
    output reg       branch_execBus,
    output reg [31:0]  data_Store,      //data_in for local memory
    input [31:0] AmuxBus,    //Data being sent to A mux input 2
    input [31:0] BmuxBus,    //Data being sent to B mux input 2
    input [31:0] memData, //Data being sent to A mux input 1
    input        mem_ackBus, //Memory acknowledgment signal coming from the global memory
    input        data_ReadyBus //register read complete
);
    //Internal signals
    reg active; // Keep track of the bus request state
    reg currentMemRead;
    reg currentMemWrite;
    reg currentReadEn;
    reg currentBranchExec;
    reg deactivate;
    reg[4:0] extraTime;
    reg currentExecComplete;
    reg currentJump;
    reg currentRdWrite; //Local signals to store the signal that triggered the bus request

    //Synchronized read and write signals coming from PE
    reg read_enSync;
    reg rdWriteSync;
    reg mem_readSync;
    reg mem_writeSync;
    reg execution_completeSync;
    reg branch_execSync;

    //Storage signals
    reg dataReadyRec; //Stores a dataReady signal received
    reg rd_writeRec; //Stores a rdWrite signal received
    reg [31:0] AmuxStore; //Storage of signal read
    reg [31:0] BmuxStore; //Storage of signal read
    reg AmuxStored;
    reg BmuxStored;

    //Optional for later if synchronization is causing trouble
    reg mem_ackSync;
    reg data_ReadySync;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bus_request <= 0;
            branch_execBus <= 0;
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
            currentExecComplete <= 0;
            deactivate <= 0;
            extraTime <= 0;
            read_enSync <= 0;
            rdWriteSync <= 0;
            mem_readSync <= 0 ;
            mem_writeSync <= 0;
            execution_completeSync <= 0;
            branch_execSync <= 0;
            dataReadyRec <= 0;
            rd_writeRec <= 0;
            AmuxStore <= 0;
            BmuxStore <= 0;
            AmuxStored <= 0;
            BmuxStored <= 0;
        end else begin
            //Synchronizing signals with clock
            read_enSync <= read_enPE;
            rdWriteSync <= rd_writePE;
            mem_readSync <= mem_readPE;
            mem_writeSync <= mem_writePE;
            execution_completeSync <= execution_completePE;
            branch_execSync <= branch_exec;

            if (data_ReadyBus == 1)
            begin
                dataReadyRec <= 1;
            end
            if (rd_writePE == 1)
            begin
                rd_writeRec <= 1;
            end

            //$display("At the start of the cycle, AmuxBus: %b and BmuxBus: %b", AmuxBus, BmuxBus);
            //$display("At the start of the cycle, AmuxStore: %b and BmuxStore: %b", AmuxStore, BmuxStore);

            if ((mem_readPE || mem_writePE || rd_writePE || read_enPE || branch_exec) && !active && (extraTime==0)) begin
                $display("Signal received to request bus");
                bus_request <= 1; // Request the bus
                $display("Signals: Mem_Read %b | Mem_Write %b | RD_Write %b | Read_En %b | Branch %b", mem_readPE, mem_writePE, rd_writePE, read_enPE, branch_exec);
                if (read_enPE)
                begin
                    $display("Local memory read");
                    currentReadEn <= 1;
                end
                else if (branch_exec && rd_writePE)
                begin
                    $display("Jump and link requested");
                    currentJump <= 1;
                end
                else if (rd_writePE)
                begin
                    $display("Received rdWrite");
                    currentRdWrite <= 1;
                end
                else if (mem_writePE)
                begin
                    $display("Global memory write");
                    currentMemWrite <= 1;
                end
                else if (mem_readPE)
                begin
                    $display("Received signal to read from global memory");
                    currentMemRead <= 1;
                end
                else if (branch_exec)
                begin
                    $display("Branching request");
                    currentExecComplete <= 1;
                end
                
            end
            if (grant) begin
                $display ("Access granted");
                if (currentBranchExec)
                begin
                    PCoutBus <= PCoutPE;
                end
                if (currentJump)
                begin
                    PCoutBus <= PCoutPE;
                    rdOutBus <= rdOutPE; //Forward select for local memory write
                    rd_writeBus <= rd_writePE;
                    data_Store <= result_inPE; //Result from ALU to be written in rd
                end
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
                    rdOutBus <= rdOutPE; //Select for local memory write
                    //$display("Rd out: %b", rdOutPE);
                    rd_writeBus <= rd_writePE;
                    data_Store <= result_inPE; //Result from ALU to be written in rd
                    $display("Data to be stored: %b", result_inPE);
                end
                if (currentReadEn)
                begin
                    rs1OutBus <= rs1OutPE;
                    rs2OutBus <= rs2OutPE;
                    read_enBus <= read_enPE;
                    $display("Registers to be read are rs1: %d and rs2: %d ", rs1OutPE, rs2OutPE);
                    reg_selectBus <= reg_selectPE;
                end
                bus_request <= 0; // Clear the request once granted
                active <= 1;
            end
            else if (active) begin
                if (!AmuxStored && (^AmuxBus === ^AmuxBus)) begin
                    AmuxStore  <= AmuxBus;
                    AmuxStored <= 1;
                    $display("Entered AmuxStore");
                end

                // Store BmuxBus once when it's valid
                if (!BmuxStored && (^BmuxBus === ^BmuxBus)) begin
                    BmuxStore  <= BmuxBus;
                    BmuxStored <= 1;
                end

                $display("Bus access is active");
                read_enBus <= 0;
                mem_readBus <= 0;
                //mem_writeBus <= 0;
                //rd_writeBus <= 0;
                if (mem_ackBus) //Only when memRead
                begin
                    $display("received mem ack");
                    memDataPE <= memData;
                    mem_ackPE <= mem_ackBus;
                    currentMemRead <= 0;
                    bus_request <= 0;
                    deactivate <= 1;
                    if (secondRead != 0)
                    begin
                        extraTime <= extraTime + 1;
                    end
                end
                else if (dataReadyRec) //Only when reading local memory. Received at least once the dataReady signal
                begin
                    $display ("Data from local memory is ready");
                    AmuxPE <= AmuxStore;
                    BmuxPE <= BmuxStore;
                    AmuxStored <= 0;
                    BmuxStored <= 0;
                    $display("Data being sent to PE is Amux: %b and Bmux: %b", AmuxStore, BmuxStore);
                    data_ReadyPE <= dataReadyRec;
                    currentReadEn <= 0;
                    bus_request <= 0;
                    deactivate <= 1;
                    if (secondRead != 0)
                    begin
                        extraTime <= extraTime + 1;
                    end
                end
                else if (execution_completePE) //Will happen at write operations 
                begin
                    $display("Execution Completed");
                    result_outBus <= result_inPE;
                    mem_addressBus <= mem_addressPE;
                    execution_completeBus <= execution_completePE;
                    currentMemWrite <= 0;
                    currentRdWrite <= 0;
                    bus_request <= 0;
                    deactivate <= 1;
                    extraTime <= extraTime + 1;
                    PCoutBus <= PCoutPE;
                    read_enBus <= read_enPE;
                    mem_readBus <= mem_readPE;
                    mem_writeBus <= mem_writePE;
                    rd_writeBus <= rd_writeRec;
                    $display("rd write in bus interface: %b", rd_writeRec);
                    branch_execBus <= branch_exec;
                end
                if (deactivate && !data_ReadyBus && !mem_ackBus)
                begin
                    active <= 0;
                    dataReadyRec <= 0;
                    rd_writeRec <= 0;
                    //AmuxStore <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
                    //BmuxStore <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
                    $display("No longer active");
                    data_ReadyPE <= data_ReadyBus;
                    mem_ackPE <= mem_ackBus;
                    execution_completeBus <= execution_completePE;
                    deactivate <= 0;
                    currentReadEn <= 0;
                end
            end
            else if (extraTime != 0 && extraTime <= 5'b11111)
            begin
                $display("Needs extra time: %b", extraTime);
                if (extraTime == 4'b010 && secondRead != 3'b111)
                begin
                    extraTime <= 0;
                    //AmuxStored <= 0;
                    //BmuxStored <= 0;
                end
                else if (extraTime == 5'b11111) 
                begin
                    extraTime <= 0;
                end
                else
                begin
                    extraTime <= extraTime + 1;
                end
            end
        end
    end
endmodule
