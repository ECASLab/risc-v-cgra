`include "input_mux.v"
`timescale 1ns / 1ps

module tb_input_mux;

    parameter NUM_CLUSTERS = 4;
    parameter NUM_PE = 4;
    parameter WIDTH = 32;
    localparam CLUSTER_WIDTH = NUM_PE * WIDTH;

    // Inputs
    reg [NUM_CLUSTERS*CLUSTER_WIDTH-1:0] mem_address_all;
    reg [NUM_CLUSTERS*CLUSTER_WIDTH-1:0] result_out_all;
    reg [NUM_CLUSTERS*CLUSTER_WIDTH-1:0] mem_write_data_all;
    reg [NUM_CLUSTERS*CLUSTER_WIDTH-1:0] PCout_all;
    reg [NUM_CLUSTERS*NUM_PE-1:0] mem_write_all;
    reg [NUM_CLUSTERS*NUM_PE-1:0] mem_read_all;
    reg [NUM_CLUSTERS*NUM_PE-1:0] execution_complete_all;
    reg [NUM_CLUSTERS*NUM_PE-1:0] branch_exec_all;
    reg [$clog2(NUM_CLUSTERS)-1:0] select;

    // Outputs
    wire [CLUSTER_WIDTH-1:0] mem_address_selected;
    wire [CLUSTER_WIDTH-1:0] result_out_selected;
    wire [CLUSTER_WIDTH-1:0] mem_write_data_selected;
    wire [CLUSTER_WIDTH-1:0] PCout_selected;
    wire [NUM_PE-1:0] mem_write_selected;
    wire [NUM_PE-1:0] mem_read_selected;
    wire [NUM_PE-1:0] execution_complete_selected;
    wire [NUM_PE-1:0] branch_exec_selected;

    // DUT
    input_mux #(NUM_CLUSTERS, NUM_PE) dut (
        .mem_address_all(mem_address_all),
        .result_out_all(result_out_all),
        .mem_write_data_all(mem_write_data_all),
        .PCout_all(PCout_all),
        .mem_write_all(mem_write_all),
        .mem_read_all(mem_read_all),
        .execution_complete_all(execution_complete_all),
        .branch_exec_all(branch_exec_all),
        .select(select),
        .mem_address_selected(mem_address_selected),
        .result_out_selected(result_out_selected),
        .mem_write_data_selected(mem_write_data_selected),
        .PCout_selected(PCout_selected),
        .mem_write_selected(mem_write_selected),
        .mem_read_selected(mem_read_selected),
        .execution_complete_selected(execution_complete_selected),
        .branch_exec_selected(branch_exec_selected)
    );
    integer i;

    // Test procedure
    initial begin
        $display("Starting input_mux testbench...");
        select = 0;

        // Initialize cluster data with identifiable values
        for (i = 0; i < NUM_CLUSTERS; i = i + 1) begin
            mem_address_all[i*CLUSTER_WIDTH +: CLUSTER_WIDTH]       = {NUM_PE{32'hA0000000 + i}};
            result_out_all[i*CLUSTER_WIDTH +: CLUSTER_WIDTH]        = {NUM_PE{32'hB0000000 + i}};
            mem_write_data_all[i*CLUSTER_WIDTH +: CLUSTER_WIDTH]    = {NUM_PE{32'hC0000000 + i}};
            PCout_all[i*CLUSTER_WIDTH +: CLUSTER_WIDTH]             = {NUM_PE{32'hD0000000 + i}};
            mem_write_all[i*NUM_PE +: NUM_PE]                       = {NUM_PE{1'b1}};
            mem_read_all[i*NUM_PE +: NUM_PE]                        = {NUM_PE{1'b0}};
            execution_complete_all[i*NUM_PE +: NUM_PE]              = {NUM_PE{1'b1}};
            branch_exec_all[i*NUM_PE +: NUM_PE]                     = {NUM_PE{1'b0}};
        end

        // Sweep through cluster selections
        for (i = 0; i < NUM_CLUSTERS; i = i + 1) begin
            select = i;
            #10;
            $display("Selected Cluster %0d", i);
            $display("  mem_address_selected       = %h", mem_address_selected);
            $display("  result_out_selected        = %h", result_out_selected);
            $display("  mem_write_data_selected    = %h", mem_write_data_selected);
            $display("  PCout_selected             = %h", PCout_selected);
            $display("  mem_write_selected         = %b", mem_write_selected);
            $display("  mem_read_selected          = %b", mem_read_selected);
            $display("  execution_complete_selected= %b", execution_complete_selected);
            $display("  branch_exec_selected       = %b", branch_exec_selected);
        end

        $display("Testbench complete.");
        $finish;
    end

endmodule

