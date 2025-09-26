
`include "memoryMux.v"

module MemoryMux_tb;

    parameter NUM_PE = 4;

    reg  [NUM_PE-1:0] grant_bus;
    reg  [NUM_PE-1:0] working;
    reg  [NUM_PE*5-1:0] rs1_flat, rs2_flat, rd_flat;
    reg  [NUM_PE-1:0] reg_select_flat, rd_write_flat, read_en_flat;
    reg  [NUM_PE*32-1:0] dataStore_flat;
    reg  [NUM_PE*32-1:0] mem_address_flat, mem_write_data_flat;
    reg  [NUM_PE-1:0] mem_read_flat, mem_write_flat;

    reg  [31:0] data_out1, data_out2;
    reg         regComplete;
    reg         mem_ack_global;
    reg  [31:0] mem_data_global;
    reg  [NUM_PE*32-1:0] result_out_flat;

    wire [4:0] rs1, rs2, rd;
    wire       reg_select, rd_write, read_en;
    wire [31:0] dataStore;
    wire [NUM_PE*32-1:0] Aop, Bop;
    wire [NUM_PE-1:0] dataReady, mem_ack;
    wire [NUM_PE*32-1:0] mem_data;
    wire [31:0] mem_address, mem_write_data;
    wire        mem_read, mem_write;
    wire [31:0] result_out;

    MemoryMux #(NUM_PE) uut (
        .grant_bus(grant_bus),
        .working(working),
        .rs1_flat(rs1_flat),
        .rs2_flat(rs2_flat),
        .rd_flat(rd_flat),
        .reg_select_flat(reg_select_flat),
        .rd_write_flat(rd_write_flat),
        .read_en_flat(read_en_flat),
        .dataStore_flat(dataStore_flat),
        .mem_address_flat(mem_address_flat),
        .result_out_flat(result_out_flat),
        .mem_write_data_flat(mem_write_data_flat),
        .mem_read_flat(mem_read_flat),
        .mem_write_flat(mem_write_flat),
        .data_out1(data_out1),
        .data_out2(data_out2),
        .regComplete(regComplete),
        .mem_ack_global(mem_ack_global),
        .mem_data_global(mem_data_global),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .reg_select(reg_select),
        .rd_write(rd_write),
        .read_en(read_en),
        .dataStore(dataStore),
        .Aop(Aop),
        .Bop(Bop),
        .dataReady(dataReady),
        .mem_ack(mem_ack),
        .mem_data(mem_data),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .result_out(result_out)
    );

    initial begin
        // Initialize inputs
        $display("##### First grant is 0 #####");
        grant_bus = 4'b0000; // No grant
        rs1_flat = {15'd0, 5'd1}; // PE 0 rs1 = 1
        rs2_flat = {15'd0, 5'd2};
        //rd_flat  = {15'd0, 5'd3};
        reg_select_flat = 4'b0001;
        //rd_write_flat   = 4'b0001;
        //read_en_flat    = 4'b0001;
        //dataStore_flat  = {96'd0, 32'hDEADBEEF};

        //mem_address_flat    = {96'd0, 32'hA0000000};
        //mem_write_data_flat = {96'd0, 32'hCAFEBABE};
        //mem_read_flat       = 4'b0001;
        //mem_write_flat      = 4'b0001;

        //data_out1 = 32'h11111111;
        //data_out2 = 32'h22222222;
        //regComplete = 1;
        //mem_ack_global = 1;
        //mem_data_global = 32'h33333333;

        #10;
        $display("##### Grant is asserted #####");
        grant_bus = 4'b0001;

        read_en_flat    = 4'b0001;

        $display("Selected rs1: %d", rs1);
        $display("Aop[0]: %h", Aop[0*32 +: 32]);
        $display("Data Ready: %b", dataReady);
        //$display("Selected dataStore: %h", dataStore);
        //$display("Global mem address: %h", mem_address);
        //$display("Global mem write data: %h", mem_write_data);
        
        //$display("mem_data[0]: %h", mem_data[0*32 +: 32]);


        #10;
        $display("##### Grant is back to 0 #####");
        grant_bus = 4'b0000;
        read_en_flat    = 4'b0000;
        $display("Selected rs1: %d", rs1);
        $display("Aop[0]: %h", Aop[0*32 +: 32]);
        $display("Data Ready: %b", dataReady);
        data_out1 = 32'h11111111;
        data_out2 = 32'h22222222;

        #10;
        $display("##### Grant for receiving data #####");
        grant_bus = 4'b0001;
        regComplete = 1;
        $display("Selected rs1: %d", rs1);
        $display("Aop[0]: %h", Aop[0*32 +: 32]);
        $display("Data Ready: %b", dataReady);

        #10;
        $display("##### Last grant deasserted #####");
        grant_bus = 4'b0000;
        regComplete = 1;
        $display("Selected rs1: %d", rs1);
        $display("Aop[0]: %h", Aop[0*32 +: 32]);
        $display("Data Ready: %b", dataReady);

        #10 $finish;
    end

endmodule
