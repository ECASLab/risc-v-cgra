module cgra_top #(
    parameter NUM_CLUSTERS = 4,
    parameter NUM_PE = 4
)(
    input clk,
    input reset,
    output [NUM_CLUSTERS-1:0] done_all,
    output [NUM_CLUSTERS*NUM_PE*32-1:0] result_out
    
);

    // === Arbiter Signals ===
    wire [NUM_CLUSTERS-1:0] req_read;
    wire [NUM_CLUSTERS-1:0] req_write;
    wire [NUM_CLUSTERS-1:0] working;
    wire [NUM_CLUSTERS-1:0] grant_read;
    wire [NUM_CLUSTERS-1:0] grant_write;

    // === Dispatcher Signals ===
    wire [NUM_CLUSTERS-1:0] write_enable_dispatch;
    wire [31:0] write_data_dispatch;
    wire [31:0] write_address_dispatch;
    wire [NUM_CLUSTERS-1:0] cluster_select_dispatch;
    wire dispatch_done;
    wire [NUM_CLUSTERS-1:0] program_loaded;

    // === Cluster ↔ Global Memory Signals ===
    wire [NUM_CLUSTERS*NUM_PE*32-1:0] mem_address_all;
    wire [NUM_CLUSTERS*NUM_PE*32-1:0] mem_write_data_all;
    wire [NUM_CLUSTERS*NUM_PE-1:0] mem_read_all;
    wire [NUM_CLUSTERS*NUM_PE-1:0] mem_write_all;
    wire [NUM_CLUSTERS*NUM_PE-1:0] execution_complete_all;
    wire [NUM_CLUSTERS*NUM_PE*32-1:0] mem_data_all;
    wire [NUM_CLUSTERS*NUM_PE-1:0] mem_ack_all;

    // === Global Memory Interface ===
    wire [NUM_PE*32-1:0] mem_address_global;
    wire [NUM_PE*32-1:0] mem_write_data_global;
    wire [NUM_PE-1:0] mem_read_global;
    wire [NUM_PE-1:0] mem_write_global;
    wire [NUM_PE*32-1:0] mem_data_global;
    wire [NUM_PE-1:0] mem_ack_global;

    // === Arbiter ===
    cluster_mem_arbiter #(.NUM_CLUSTERS(NUM_CLUSTERS)) arbiter (
        .clk(clk),
        .reset(reset),
        .req_read(req_read),
        .req_write(req_write),
        .working(working),
        .grant_read(grant_read),
        .grant_write(grant_write)
    );

    // === Request Interface ===
    cluster_request_interface #(.NUM_CLUSTERS(NUM_CLUSTERS), .NUM_PE(NUM_PE)) req_if (
        .mem_read_all(mem_read_all),
        .mem_write_all(mem_write_all),
        .read_req(req_read),
        .write_req(req_write)
    );

    // === Memory Mux ===
    global_memory_mux #(.NUM_CLUSTERS(NUM_CLUSTERS), .NUM_PE(NUM_PE)) mux (
        .grant_read(grant_read),
        .grant_write(grant_write),
        .mem_address_in(mem_address_all),
        .mem_write_data_in(mem_write_data_all),
        .mem_read_in(mem_read_all),
        .mem_write_in(mem_write_all),
        .mem_data_global(mem_data_global),
        .mem_ack_global(mem_ack_global),
        .mem_address_global(mem_address_global),
        .mem_write_data_global(mem_write_data_global),
        .mem_read_global(mem_read_global),
        .mem_write_global(mem_write_global),
        .mem_data_out(mem_data_all),
        .mem_ack_out(mem_ack_all)
    );

    // === Global Memory ===
    global_memory #(.NUM_PE(NUM_PE)) global_mem (
        .clk(clk),
        .reset(reset),
        .mem_address(mem_address_global),
        .mem_write_data(mem_write_data_global),
        .mem_write(mem_write_global),
        .mem_read(mem_read_global),
        .mem_read_data(mem_data_global),
        .mem_ack(mem_ack_global)
    );

    // === Instruction Dispatcher ===
    global_instruction_dispatcher #(.NUM_CLUSTERS(NUM_CLUSTERS), .INSTR_PER_CLUSTER(4)) dispatcher (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable_dispatch),
        .write_data(write_data_dispatch),
        .write_address(write_address_dispatch),
        .cluster_select(cluster_select_dispatch),
        .dispatch_done(dispatch_done),
        .program_loaded(program_loaded)
    );

    // === Cluster Instantiation ===
    genvar c;
    generate
        for (c = 0; c < NUM_CLUSTERS; c = c + 1) begin : cluster_block
            localparam [1:0] CLUS_ID = c[1:0];  // constant per instance
            local_bus_control #(.NUM_PE(NUM_PE)) cluster (
                .clk(clk),
                .reset(reset),
                .Clusterid(CLUS_ID),
                .mem_ack_global(mem_ack_all[c*NUM_PE +: NUM_PE]),
                .mem_data_global(mem_data_all[c*NUM_PE*32 +: NUM_PE*32]),
                .program_loaded(program_loaded[c]),
                .mem_address_global(mem_address_all[c*NUM_PE*32 +: NUM_PE*32]),
                .result_out(result_out[c*NUM_PE*32 +: NUM_PE*32]), 
                .mem_write_data_global(mem_write_data_all[c*NUM_PE*32 +: NUM_PE*32]),
                .mem_write_global(mem_write_all[c*NUM_PE +: NUM_PE]),
                .mem_read_global(mem_read_all[c*NUM_PE +: NUM_PE]),
                .branch_exec(), // optional
                .cluster_select(cluster_select_dispatch[c]),
                .write_enable(write_enable_dispatch[c]),
                .write_data(write_data_dispatch),
                .write_address(write_address_dispatch),
                .done(done_all[c])
            );

            assign working[c] = |mem_read_all[c*NUM_PE +: NUM_PE] | |mem_write_all[c*NUM_PE +: NUM_PE];
        end
    endgenerate

endmodule
