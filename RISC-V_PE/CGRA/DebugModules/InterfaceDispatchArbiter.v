`include "../../Cluster/LocalBus:Cluster/LocalBus.v"
`include "../MemoryInterface.v"
`include "../InstructionDispatcher.v"
`include "../ClusterArbiter.v" 

module bus_interface_test_top #(
    parameter NUM_CLUSTERS = 1,
    parameter NUM_PE = 4,
    parameter INSTR_PER_CLUSTER = 4
)(
    input clk,
    input reset,

    // === Global Memory Inputs ===
    input [NUM_PE-1:0] mem_ack_global,
    input [NUM_PE*32-1:0] mem_data_global,

    // === Global Memory Outputs ===
    output [NUM_PE*32-1:0] mem_address_global,
    output [NUM_PE*32-1:0] mem_write_data_global,
    output [NUM_PE-1:0] branch_exec,
    output [NUM_PE*32-1:0] result_out,
    output done,

    // === Arbiter Observables ===
    output [NUM_CLUSTERS-1:0] grant_read,
    output [NUM_CLUSTERS-1:0] grant_write
);

    // === Internal Signals ===
    wire write_enable;
    wire [31:0] write_data;
    wire [31:0] write_address;
    wire cluster_select;
    wire program_loaded;
    wire dispatch_done;

    wire [NUM_PE-1:0] mem_write_global;
    wire [NUM_PE-1:0] mem_read_global;

    wire [NUM_CLUSTERS-1:0] read_req;
    wire [NUM_CLUSTERS-1:0] write_req;

    reg [NUM_CLUSTERS-1:0] working;

    integer i;

    // === Local Bus Control ===
    local_bus_control #(.NUM_PE(NUM_PE)) cluster_bus (
        .clk(clk),
        .reset(reset),
        .mem_ack_global(mem_ack_global),
        .mem_data_global(mem_data_global),
        .program_loaded(program_loaded),
        .write_enable(write_enable),
        .write_data(write_data),
        .write_address(write_address),
        .cluster_select(cluster_select),
        .Clusterid(2'b00),
        .mem_address_global(mem_address_global),
        .result_out(result_out),
        .mem_write_data_global(mem_write_data_global),
        .mem_write_global(mem_write_global),
        .mem_read_global(mem_read_global),
        .branch_exec(branch_exec),
        .done(done)
    );

    // === Memory Request Interface ===
    cluster_request_interface #(.NUM_CLUSTERS(NUM_CLUSTERS), .NUM_PE(NUM_PE)) req_if (
        .mem_read_all(mem_read_global),
        .mem_write_all(mem_write_global),
        .read_req(read_req),
        .write_req(write_req)
    );

    // === Instruction Dispatcher ===
    global_instruction_dispatcher #(.NUM_CLUSTERS(NUM_CLUSTERS), .INSTR_PER_CLUSTER(INSTR_PER_CLUSTER)) inst_disp (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .write_data(write_data),
        .write_address(write_address),
        .cluster_select(cluster_select),
        .program_loaded(program_loaded),
        .dispatch_done(dispatch_done)
    );

    // === Arbiter ===
    cluster_mem_arbiter #(.NUM_CLUSTERS(NUM_CLUSTERS)) arbiter (
        .clk(clk),
        .reset(reset),
        .req_read(read_req),
        .req_write(write_req),
        .working(working), // You can wire this from cluster or simulate it
        .grant_read(grant_read),
        .grant_write(grant_write)
    );

    always @(posedge clk or posedge reset) begin
    if (reset) begin
        working <= 0;
    end else begin
        for (i = 0; i < NUM_CLUSTERS; i++) begin
            if (grant_read[i] || grant_write[i])
                working[i] <= 1;
            else if (mem_ack_global != 0 || mem_write_global != 0)
                working[i] <= 0;
        end
    end
    end

endmodule
