`include "output_demux.v"
`timescale 1ns / 1ps

module tb_output_demux;

    parameter NUM_CLUSTERS = 4;
    parameter NUM_PE = 4;
    parameter WIDTH = 32;
    localparam CLUSTER_WIDTH = NUM_PE * WIDTH;

    // Inputs
    reg [CLUSTER_WIDTH-1:0] PCin_in;
    reg [CLUSTER_WIDTH-1:0] instructions_in;
    reg [NUM_PE-1:0] mem_ack_in;
    reg [CLUSTER_WIDTH-1:0] mem_data_in;
    reg [$clog2(NUM_CLUSTERS)-1:0] select;

    // Outputs
    wire [NUM_CLUSTERS*CLUSTER_WIDTH-1:0] PCin_out;
    wire [NUM_CLUSTERS*CLUSTER_WIDTH-1:0] instructions_out;
    wire [NUM_CLUSTERS*CLUSTER_WIDTH-1:0] mem_data_out;
    wire [NUM_CLUSTERS*NUM_PE-1:0] mem_ack_out;

    // DUT
    output_demux #(NUM_CLUSTERS, NUM_PE) dut (
        .PCin_in(PCin_in),
        .instructions_in(instructions_in),
        .mem_ack_in(mem_ack_in),
        .mem_data_in(mem_data_in),
        .select(select),
        .PCin_out(PCin_out),
        .instructions_out(instructions_out),
        .mem_data_out(mem_data_out),
        .mem_ack_out(mem_ack_out)
    );
    integer i;

    // Test procedure
    initial begin
        $display("Starting output_demux testbench...");
        select = 0;

        // Initialize input bundle with identifiable values
        PCin_in         = {NUM_PE{32'hAA000000}};
        instructions_in = {NUM_PE{32'hBB000000}};
        mem_data_in     = {NUM_PE{32'hCC000000}};
        mem_ack_in      = {NUM_PE{1'b1}};

        // Sweep through cluster destinations
        for (i = 0; i < NUM_CLUSTERS; i = i + 1) begin
            select = i;
            #10;
            $display("Routing to Cluster %0d", i);
            $display("  PCin_out[%0d]         = %h", i, PCin_out[i*CLUSTER_WIDTH +: CLUSTER_WIDTH]);
            $display("  instructions_out[%0d] = %h", i, instructions_out[i*CLUSTER_WIDTH +: CLUSTER_WIDTH]);
            $display("  mem_data_out[%0d]     = %h", i, mem_data_out[i*CLUSTER_WIDTH +: CLUSTER_WIDTH]);
            $display("  mem_ack_out[%0d]      = %b", i, mem_ack_out[i*NUM_PE +: NUM_PE]);
        end

        $display("Testbench complete.");
        $finish;
    end

endmodule
