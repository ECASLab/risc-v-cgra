module output_demux #(parameter NUM_CLUSTERS = 4, NUM_PE = 4)(
    input  [NUM_PE*32-1:0] PCin_in,
    input  [NUM_PE*32-1:0] instructions_in,
    input  [NUM_PE-1:0] mem_ack_in,
    input  [NUM_PE*32-1:0] mem_data_in,
    input  [$clog2(NUM_CLUSTERS)-1:0] select,

    output [NUM_CLUSTERS*NUM_PE*32-1:0] PCin_out,
    output [NUM_CLUSTERS*NUM_PE*32-1:0] instructions_out,
    output [NUM_CLUSTERS*NUM_PE*32-1:0] mem_data_out,
    output [NUM_CLUSTERS*NUM_PE-1:0]    mem_ack_out
);

    localparam CLUSTER_WIDTH = NUM_PE * 32;

    genvar i;
    generate
        for (i = 0; i < NUM_CLUSTERS; i = i + 1) begin : demux
            assign PCin_out[i*CLUSTER_WIDTH +: CLUSTER_WIDTH]          = (select == i) ? PCin_in         : {CLUSTER_WIDTH{1'b0}};
            assign instructions_out[i*CLUSTER_WIDTH +: CLUSTER_WIDTH]  = (select == i) ? instructions_in : {CLUSTER_WIDTH{1'b0}};
            assign mem_data_out[i*CLUSTER_WIDTH +: CLUSTER_WIDTH]      = (select == i) ? mem_data_in     : {CLUSTER_WIDTH{1'b0}};
            assign mem_ack_out[i*NUM_PE +: NUM_PE]                     = (select == i) ? mem_ack_in      : {NUM_PE{1'b0}};
        end
    endgenerate

endmodule
