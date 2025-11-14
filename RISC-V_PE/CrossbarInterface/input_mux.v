module input_mux #(parameter NUM_CLUSTERS = 4, NUM_PE = 4)(
    input  [NUM_CLUSTERS*NUM_PE*32-1:0] mem_address_all,
    input  [NUM_CLUSTERS*NUM_PE*32-1:0] result_out_all,
    input  [NUM_CLUSTERS*NUM_PE*32-1:0] mem_write_data_all,
    input  [NUM_CLUSTERS*NUM_PE*32-1:0] PCout_all,
    input  [NUM_CLUSTERS*NUM_PE-1:0]    mem_write_all,
    input  [NUM_CLUSTERS*NUM_PE-1:0]    mem_read_all,
    input  [NUM_CLUSTERS*NUM_PE-1:0]    execution_complete_all,
    input  [NUM_CLUSTERS*NUM_PE-1:0]    branch_exec_all,
    input  [$clog2(NUM_CLUSTERS)-1:0]   select,

    output [NUM_PE*32-1:0] mem_address_selected,
    output [NUM_PE*32-1:0] result_out_selected,
    output [NUM_PE*32-1:0] mem_write_data_selected,
    output [NUM_PE*32-1:0] PCout_selected,
    output [NUM_PE-1:0]    mem_write_selected,
    output [NUM_PE-1:0]    mem_read_selected,
    output [NUM_PE-1:0]    execution_complete_selected,
    output [NUM_PE-1:0]    branch_exec_selected
);

    localparam CLUSTER_WIDTH = NUM_PE * 32;

    assign mem_address_selected       = mem_address_all[select*CLUSTER_WIDTH +: CLUSTER_WIDTH];
    assign result_out_selected    = result_out_all[select*CLUSTER_WIDTH +: CLUSTER_WIDTH];
    assign mem_write_data_selected = mem_write_data_all[select*CLUSTER_WIDTH +: CLUSTER_WIDTH];
    assign PCout_selected  = PCout_all[select*NUM_PE +: NUM_PE];
    assign mem_write_selected  = mem_write_all[select*NUM_PE +: NUM_PE];
    assign mem_read_selected  = mem_read_all[select*NUM_PE +: NUM_PE];
    assign execution_complete_selected  = execution_complete_all[select*NUM_PE +: NUM_PE];
    assign branch_exec_selected  = branch_exec_all[select*NUM_PE +: NUM_PE];

endmodule
