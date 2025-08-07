module MemoryMux #(
    parameter NUM_PE = 4
)(
    //Inputs from PE to route to local mem
    input  [NUM_PE-1:0] grant_bus,
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

    integer i;
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

        for (i = 0; i < NUM_PE; i = i + 1) begin
            if (grant_bus[i]) begin
                rs1        = rs1_flat[i*5 +: 5];
                rs2        = rs2_flat[i*5 +: 5];
                rd         = rd_flat[i*5 +: 5];
                reg_select = reg_select_flat[i];
                rd_write   = rd_write_flat[i];
                read_en    = read_en_flat[i];
                dataStore  = dataStore_flat[i*32 +: 32];
                Aop[i*32 +: 32] = data_out1;
                Bop[i*32 +: 32] = data_out2;
                dataReady[i] = regComplete;
                mem_ack[i] = mem_ack_global;
                mem_data[i*32 +: 32] = mem_data_global;
                mem_address = mem_address_flat[i*32 +: 32];
                mem_write_data = mem_write_data_flat[i*32 +: 32];
                mem_read = mem_read_flat[i];
                mem_write = mem_write_data_flat[i];
                result_out = result_out_flat[i*32 +: 32];
            end
        end
    end

endmodule
