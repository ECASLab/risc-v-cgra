`include "BusArbiter.v"
`include "PEInterface.v"
`include "DataRegs.v"
`include "memoryMux.v"


module local_bus_top #(parameter NUM_PE = 4)(
    input clk,                     // Clock signal
    input reset,                   // Reset signal
    input [NUM_PE*32-1:0] PCin,            // Program counters received by the interface controller
    input [NUM_PE*32-1:0] instructions,    // Instructions received by the interface controller
    input mem_ack_global,  // Coming from global memory
    input [31:0] mem_data_global, // Data being read from global mem
    
    output [31:0] mem_address_global, // Addresses to read from global mem
    output [31:0] result_out,         // Result from PE output *Might be an internal signal
    output [31:0] mem_write_data_global, // Data output from PEs to write to memory *Might use the result_out
    output [NUM_PE*32-1:0] PCout,            // PC output from all PEs, to check for breaks and jumps
    output mem_write_global,   // To send write signal to global mem
    output mem_read_global,    // To send read signal to global mem
    output [NUM_PE-1:0] execution_complete, // Indicates to cluster controller that execution is completed
    output [NUM_PE-1:0] branch_exec         // Indicates to controller that a break or jump is initiated
    
);

    // Internal signals for the interconnections
    wire [NUM_PE-1:0] bus_request;        // Bus request signals from PEs
    wire [NUM_PE-1:0] working;
    wire [NUM_PE-1:0] muxSel;
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
    wire [NUM_PE*32-1:0] mem_address;  
    wire [NUM_PE*32-1:0] mem_write_data;
    wire [NUM_PE*32-1:0] mem_data;
    wire [NUM_PE-1:0] mem_ack;
    wire [NUM_PE-1:0] mem_write;
    wire [NUM_PE-1:0] mem_read;
    wire [NUM_PE*32-1:0] result_out_flat;

    reg [3:0] granted_index;
    reg       dataReady_index;

    // Arbiter
    bus_arbiter #(NUM_PE) arb (
        .clk(clk),
        .reset(reset),
        .req(bus_request),
        .working(working),
        .grant(grant)
    );

    wire [4:0] rs1_mux, rs2_mux, rd_mux;
    wire       reg_select_mux, rd_write_mux, read_en_mux, regComplete_mux, mem_ack_mux;
    wire [31:0] dataStore_mux, data_out1_mux, data_out2_mux, mem_data_mux, result_out_mux;

    assign mem_write_data_global = mem_write_global ? result_out : 0;

    MemoryMux #(NUM_PE) localMemMux (
        .grant_bus(muxSel),
        .working(working),
        .rs1_flat(rs1),
        .rs2_flat(rs2),
        .rd_flat(rd),
        .reg_select_flat(reg_select),
        .rd_write_flat(rd_write),
        .read_en_flat(read_en),
        .dataStore_flat(dataStore),
        .result_out_flat(result_out_flat),
        .rs1(rs1_mux),
        .rs2(rs2_mux),
        .rd(rd_mux),
        .reg_select(reg_select_mux),
        .rd_write(rd_write_mux),
        .read_en(read_en_mux),
        .dataStore(dataStore_mux),
        .data_out1(data_out1_mux),
        .data_out2(data_out2_mux),
        .regComplete(dataReady_index),
        .Aop(Aop),
        .Bop(Bop),
        .result_out(result_out),
        .dataReady(dataReady),
        .mem_address_flat(mem_address),
        .mem_write_data_flat(mem_write_data),
        .mem_read_flat(mem_read),
        .mem_write_flat(mem_write),
        .mem_ack_global(mem_ack_global),
        .mem_data_global(mem_data_global),
        .mem_ack(mem_ack),
        .mem_data(mem_data),
        .mem_address(mem_address_global),
        .mem_write_data(mem_write_data_global),
        .mem_read(mem_read_global),
        .mem_write(mem_write_global)
    );

    register_system localMem (
        .clk(clk),
        .selRD(rd_mux),
        .selRS1(rs1_mux),
        .selRS2(rs2_mux),
        .reg_select(reg_select_mux),
        .data_in(dataStore_mux),
        .rdwrite(rd_write_mux),
        .read_en(read_en_mux),
        .data_out1(data_out1_mux),  
        .data_out2(data_out2_mux),
        .regComplete(regComplete_mux)
    );


    // 4 PE Interfaces
    genvar i;
    generate
        for (i = 0; i < NUM_PE; i = i + 1) begin : pe_interface_block
            //assign result_mux[i*32 +: 32] = (mem_write[i]) ? mem_write_data_global : result_out; // Conditional operation
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
                .mem_ackBus(mem_ack[i]),
                .data_ReadyBus(dataReady[i]),
                .memData(mem_data[i*32 +: 32]),
                .mem_addressBus(mem_address[i*32 +: 32]),
                .result_outBus(result_out_flat[i*32 +: 32]),
                .PCoutBus(PCout[i*32 +: 32]),
                .rs1OutBus(rs1[i*5 +: 5]),
                .rs2OutBus(rs2[i*5 +: 5]),
                .rdOutBus(rd[i*5 +: 5]),
                .reg_selectBus(reg_select[i]),
                .mem_writeBus(mem_write[i]),
                .mem_readBus(mem_read[i]),
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
            assign muxSel[i] = muxSel_i;
        end
    endgenerate

    //reg [3:0] temp; 

    always @(posedge clk or posedge reset) begin
        if (reset)
        begin
            granted_index <= 0;
            dataReady_index <= 0;
        end
        else begin
            dataReady_index <= regComplete_mux; //Delay the signal sent to the mux
            $display("This is the dataReady_index: %b", dataReady_index);
        end
    end

endmodule
