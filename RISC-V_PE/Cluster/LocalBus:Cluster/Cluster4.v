`include "../Arbiter/BusArbiter4PE.v"
`include "../PE:Interface/PEinterface.v"
`include "../LocalMem4PE/dataRegs4.v"


module local_bus_top #(parameter NUM_PE = 4)(
    input clk,                     // Clock signal
    input reset,                   // Reset signal
    input [NUM_PE*32-1:0] PCin,            // Program counters received by the interface controller
    input [NUM_PE*32-1:0] instructions,    // Instructions received by the interface controller
    input [NUM_PE-1:0] mem_ack_global,  // Coming from global memory
    input [NUM_PE*32-1:0] mem_data_global, // Data being read from global mem
    
    output [NUM_PE*32-1:0] mem_address_global, // Addresses to read from global mem
    output [NUM_PE*32-1:0] result_out,         // Result from PE output *Might be an internal signal
    output [NUM_PE*32-1:0] mem_write_data_global, // Data output from PEs to write to memory *Might use the result_out
    output [NUM_PE*32-1:0] PCout,            // PC output from all PEs, to check for breaks and jumps
    output [NUM_PE-1:0] mem_write_global,   // To send write signal to global mem
    output [NUM_PE-1:0] mem_read_global,    // To send read signal to global mem
    output [NUM_PE-1:0] execution_complete, // Indicates to cluster controller that execution is completed
    output [NUM_PE-1:0] branch_exec         // Indicates to controller that a break or jump is initiated
    
);

    // Internal signals for the interconnections
    wire [NUM_PE-1:0] bus_request;        // Bus request signals from PEs
    wire [NUM_PE-1:0] working;
    wire [NUM_PE-1:0] grant;              // Grant signals from arbiter to PEs

    // Internal signals
    //Connections between PEInterface module and local memory or global memory
    wire [NUM_PE*32-1:0] Aop;  //Data sent to second input of Amux (local mem)
    wire [NUM_PE*32-1:0] Bop;    //Data sent to second input of Bmux (local mem)
    wire [NUM_PE-1:0] dataReady;     //Signal that data is ready in local bus
    wire [NUM_PE*5-1:0] rs1;        //Select data from PE to be sent to local memory
    wire [NUM_PE*5-1:0] rs2;        //Select data from PE to be sent to local memory
    wire [NUM_PE*5-1:0] rd;         //Select data from PE to be sent to local memory
    wire [NUM_PE-1:0]  reg_select;    //Select signal for local memory (read 1 or 2 data)
    wire [NUM_PE-1:0]  rd_write;      //Signal to write to local memory
    wire [NUM_PE-1:0]  read_en;       //Signal to read from local memory
    wire [NUM_PE*32-1:0] dataStore;    //Data to be written into local memory

    reg [NUM_PE-1:0] granted_index;
    reg dataReady_index;

    // Arbiter
    bus_arbiter4 #(NUM_PE) arb (
        .clk(clk),
        .reset(reset),
        .req(bus_request),
        .working(working),
        .grant(grant)
    );

    assign mem_write_data_global[31:0] = mem_write_global[0] ? result_out[31:0] : 0;
    assign mem_write_data_global[63:32] = mem_write_global[1] ? result_out[63:32] : 0;
    assign mem_write_data_global[95:64] = mem_write_global[2] ? result_out[95:64] : 0;
    assign mem_write_data_global[127:96] = mem_write_global[3] ? result_out[127:96] : 0;

    register_system localMem (
        .clk(clk),
        .selRD0(rd[4:0]),
        .selRD1(rd[9:5]),
        .selRD2(rd[14:10]),
        .selRD3(rd[19:15]),
        .selRS0(rs1[4:0]),
        .selRS2(rs1[9:5]),
        .selRS4(rs1[14:10]),
        .selRS6(rs1[19:15]),
        .selRS1(rs2[4:0]),
        .selRS3(rs2[9:5]),
        .selRS5(rs2[14:10]),
        .selRS7(rs2[19:15]),
        .reg_select0(reg_select[0]),
        .reg_select1(reg_select[1]),
        .reg_select2(reg_select[2]),
        .reg_select3(reg_select[3]),
        .data_in0(dataStore[31:0]),
        .data_in1(dataStore[63:32]),
        .data_in2(dataStore[95:64]),
        .data_in3(dataStore[127:96]),
        .rdwrite0(rd_write[0]),
        .rdwrite1(rd_write[1]),
        .rdwrite2(rd_write[2]),
        .rdwrite3(rd_write[3]),
        .read_en0(read_en[0]),
        .read_en1(read_en[1]),
        .read_en2(read_en[2]),
        .read_en3(read_en[3]),
        .data_out0(Aop[31:0]), 
        .data_out1(Bop[31:0]),  
        .data_out2(Aop[63:32]),
        .data_out3(Bop[63:32]), 
        .data_out4(Aop[95:64]),  
        .data_out5(Bop[95:64]),
        .data_out6(Aop[127:96]), 
        .data_out7(Bop[127:96]),  
        .regComplete0(dataReady[0]),
        .regComplete1(dataReady[1]),
        .regComplete2(dataReady[2]),
        .regComplete3(dataReady[3])
    );


    // 4 PE Interfaces
    genvar i;
    generate
        for (i = 0; i < NUM_PE; i = i + 1) begin : pe_interface_block
            wire grant_i = grant[i];
            wire bus_request_i;
            wire working_i;
            wire muxSel_i;

            PE_system pe_intf (
                .clk(clk),
                .reset(reset),
                .PCin(PCin[i*32 +: 32]),
                .grant(grant_i),
                .instructionBus(instructions[i*32 +: 32]),
                .AmuxBus(Aop[i*32 +: 32]),
                .BmuxBus(Bop[i*32 +: 32]),
                .mem_ackBus(mem_ack_global[i]),
                .data_ReadyBus(dataReady[i]),
                .memData(mem_data_global[i*32 +: 32]),
                .mem_addressBus(mem_address_global[i*32 +: 32]),
                .result_outBus(result_out[i*32 +: 32]),
                .PCoutBus(PCout[i*32 +: 32]),
                .rs1OutBus(rs1[i*5 +: 5]),
                .rs2OutBus(rs2[i*5 +: 5]),
                .rdOutBus(rd[i*5 +: 5]),
                .reg_selectBus(reg_select[i]),
                .mem_writeBus(mem_write_global[i]),
                .mem_readBus(mem_read_global[i]),
                .rd_writeBus(rd_write[i]),
                .read_enBus(read_en[i]),
                .bus_request(bus_request_i),
                .working(working_i),
                .muxSel(muxSel_i),
                .execution_complete(execution_complete[i]),
                .data_Store(dataStore[i*32 +: 32]),
                .branch_exec(branch_exec[i]),
                .id(i[1:0])
            );
            assign bus_request[i] = bus_request_i;
            assign working[i] = working_i;
        end
    endgenerate

    //reg [3:0] temp; 

    always @(posedge clk or posedge reset) begin
        if (reset)
        begin
            //granted_index <= 0;
            //dataReady_index <= 0;
        end
        else begin
            //dataReady_index[0] <= regComplete0; //Delay the signal sent to the mux
            //$display("This is the dataReady_index: %b", dataReady_index);
        end
    end

endmodule
