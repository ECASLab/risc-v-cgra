module MemoryMux #(
    parameter NUM_PE = 4
)(
    //Inputs from PE to route to local mem
    input  [NUM_PE-1:0] grant_bus,
    input  [NUM_PE-1:0] working,
    input  [NUM_PE*5-1:0] rs1_flat,
    input  [NUM_PE*5-1:0] rs2_flat,
    input  [NUM_PE*5-1:0] rd_flat,
    input  [NUM_PE-1:0] reg_select_flat,
    input  [NUM_PE-1:0] rd_write_flat,
    input  [NUM_PE-1:0] read_en_flat,
    input  [NUM_PE*32-1:0] dataStore_flat,

    //Inputs from PE to route to global mem
    input  [NUM_PE*32-1:0] mem_address_flat,
    input  [NUM_PE*32-1:0] mem_write_data_flat,
    input  [NUM_PE-1:0]    mem_read_flat,
    input  [NUM_PE-1:0]    mem_write_flat,
    input  [NUM_PE*32-1:0] result_out_flat,

    //Inputs from local memory to send to PEs
    input  [31:0] data_out1,
    input  [31:0] data_out2,
    input         regComplete,

    //Inputs from global memory
    input         mem_ack_global,
    input [31:0]  mem_data_global,

    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] rd,
    output reg       reg_select,
    output reg       rd_write,
    output reg       read_en,
    output reg [31:0] dataStore,
    output reg [NUM_PE*32-1:0] Aop,
    output reg [NUM_PE*32-1:0] Bop,
    output reg [NUM_PE-1:0] dataReady,
    output reg [NUM_PE-1:0] mem_ack,
    output reg [NUM_PE*32-1:0] mem_data,
    output reg [31:0] mem_address,
    output reg [31:0] mem_write_data,
    output reg        mem_read,
    output reg        mem_write,
    output reg [31:0] result_out
);
    reg [NUM_PE*5-1:0] rs1Save, rs2Save, rdSave;
    reg [NUM_PE-1:0] regSelSave, rdWriteSave, readEnSave, memReadSave, memWriteSave;
    reg [NUM_PE*32-1:0] dataStoreSave, memAddressSave, memWriteDataSave, resultSave;
    reg memAckSave, regCompleteSave;
    reg [31:0] data1Save, data2Save, memDataSave;

    integer i;
    reg [3:0] granted;
    reg regCompleted;
    reg memAcked;
    always @(*) begin
        rs1        = 5'd0;
        rs2        = 5'd0;
        rd         = 5'd0;
        reg_select = 1'b0;
        rd_write   = 1'b0;
        read_en    = 1'b0;
        dataStore  = 32'd0;
        Aop        = 0;
        Bop        = 0;
        dataReady  = 0;
        mem_ack    = 0;
        mem_data   = 0;
        mem_address = 0;
        mem_write_data = 0;
        mem_read = 0;
        mem_write = 0;
        result_out = 0;
        granted = 0;
        regCompleted = 0;

        granted = grant_bus;
        regCompleted = regComplete;
        memAcked = mem_ack_global;

        //$display("Grant/Select value: %b", granted);
        //$display("Data out 1 received: %b and regComplete received: %b", data_out1, regCompleted);
        
        for (i = 0; i < NUM_PE; i = i + 1) begin
            //$display("Value of i: %d and value of NUM_PE: %d and value of grant: %b", i, NUM_PE, granted);
            if (granted[i]) begin
                $display("I entered the grant in the memory mux");
                if (read_en_flat[i]) begin
                    rs1        = rs1_flat[i*5 +: 5];
                    //$display("RS1 signal is %b", rs1);
                    rs2        = rs2_flat[i*5 +: 5];
                    reg_select = reg_select_flat[i];
                    read_en    = read_en_flat[i];
                end
                else if (rd_write_flat[i]) begin
                    rd         = rd_flat[i*5 +: 5];
                    rd_write   = rd_write_flat[i];
                    dataStore  = dataStore_flat[i*32 +: 32];
                end
                else if (mem_write_flat[i]) begin
                    mem_address = mem_address_flat[i*32 +: 32];
                    mem_write_data = mem_write_data_flat[i*32 +: 32];
                    mem_write = mem_write_data_flat[i];
                end
                else if (mem_read_flat[i]) begin
                    mem_address = mem_address_flat[i*32 +: 32];
                    $display("ID%d Entered memory read request with mem_address %b", i, mem_address);
                    mem_read = mem_read_flat[i];
                end
                /* else if (mem_ack_global) begin
                    mem_data[i*32 +: 32] = mem_data_global;
                    mem_ack[i] = mem_ack_global;
                end */
                result_out = result_out_flat[i*32 +: 32];
            end

            if (working[i] && regCompleted) begin
                Aop[i*32 +: 32] = data_out1;
                //$display("A opperand: %b", data_out1);
                Bop[i*32 +: 32] = data_out2;
                dataReady[i] = regCompleted;
            end
            else if (working[i] && memAcked) begin
                mem_data[i*32 +: 32] = mem_data_global;
                mem_ack[i] = memAcked;
            end
        end
        
        granted = 4'b0;
        regCompleted = 0;
        memAcked = 0;
    end

endmodule
