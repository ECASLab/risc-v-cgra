module global_memory_mux #(
    parameter NUM_CLUSTERS = 4,
    parameter NUM_PE = 4
)(
    // Arbiter grant signals
    input [NUM_CLUSTERS-1:0] grant_read,
    input [NUM_CLUSTERS-1:0] grant_write,

    // Cluster inputs to global memory
    input [NUM_CLUSTERS*NUM_PE*32-1:0] mem_address_in,
    input [NUM_CLUSTERS*NUM_PE*32-1:0] mem_write_data_in,
    input [NUM_CLUSTERS*NUM_PE-1:0] mem_read_in,
    input [NUM_CLUSTERS*NUM_PE-1:0] mem_write_in,

    // Global memory outputs
    input [NUM_PE*32-1:0] mem_data_global,
    input [NUM_PE-1:0] mem_ack_global,

    // Routed outputs to global memory
    output reg [NUM_PE*32-1:0] mem_address_global,
    output reg [NUM_PE*32-1:0] mem_write_data_global,
    output reg [NUM_PE-1:0] mem_read_global,
    output reg [NUM_PE-1:0] mem_write_global,

    // Routed responses back to clusters
    output reg [NUM_CLUSTERS*NUM_PE*32-1:0] mem_data_out,
    output reg [NUM_CLUSTERS*NUM_PE-1:0] mem_ack_out
);

    integer i;
    reg [NUM_CLUSTERS*NUM_PE-1:0] mem_read_store;
    reg [NUM_CLUSTERS*NUM_PE-1:0] mem_write_store;

    always @(*) begin
        // Default: zero outputs
        mem_address_global     = 0;
        mem_write_data_global  = 0;
        mem_read_global        = 0;
        mem_write_global       = 0;
        mem_data_out           = 0;
        mem_ack_out            = 0;

        if (mem_read_in != 0 )
        begin
            mem_read_store = mem_read_in;
        end

        if (mem_write_in != 0 )
        begin
            mem_write_store = mem_write_in;
        end

        for (i = 0; i < NUM_CLUSTERS; i = i + 1) begin
            if (grant_read[i]) begin
                mem_address_global = mem_address_in[i*NUM_PE*32 +: NUM_PE*32];
                mem_read_global    = mem_read_store[i*NUM_PE +: NUM_PE];
            end
            if (mem_ack_global != 0)
            begin
                mem_data_out[i*NUM_PE*32 +: NUM_PE*32] = mem_data_global;
                mem_ack_out[i*NUM_PE +: NUM_PE]        = mem_ack_global;
            end
            else if (grant_write[i]) begin
                mem_address_global    = mem_address_in[i*NUM_PE*32 +: NUM_PE*32];
                mem_write_data_global = mem_write_data_in[i*NUM_PE*32 +: NUM_PE*32];
                mem_write_global      = mem_write_store[i*NUM_PE +: NUM_PE];
            end
        end
    end
endmodule
