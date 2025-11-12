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
            $display ("Received a mem read signal right now");
            mem_read_store = mem_read_in;
            $display ("Mem read is: %b", mem_read_store);
        end

        if (mem_write_in != 0 )
        begin
            $display ("Received a mem write signal right now");
            mem_write_store = mem_write_in;
            $display ("Mem write is: %b", mem_write_store);
        end

        if (mem_data_global != 0)
        begin
            //$display("Memory data coming from global: %h with grant_read %b", mem_data_global, grant_read);
        end

        for (i = 0; i < NUM_CLUSTERS; i = i + 1) begin
            if (grant_read[i]) begin
                $display ("ACCESS TO READ HAS BEEN GRANTED");
                mem_address_global = mem_address_in[i*NUM_PE*32 +: NUM_PE*32];
                $display ("Address global sent to memory: %h", mem_address_global);
                mem_read_global    = mem_read_store[i*NUM_PE +: NUM_PE];
                $display ("Mem read signal sent to memory: %b", mem_read_global);
            end
            if (mem_ack_global != 0)
            begin
                mem_data_out[i*NUM_PE*32 +: NUM_PE*32] = mem_data_global;
                $display("Mem data sent back to cluster: %h", mem_data_out[i*NUM_PE*32 +: NUM_PE*32]);
                mem_ack_out[i*NUM_PE +: NUM_PE]        = mem_ack_global;
                $display("Mem ack signal sent back to cluster: %b", mem_ack_out[i*NUM_PE +: NUM_PE]);
            end
            else if (grant_write[i]) begin
                mem_address_global    = mem_address_in[i*NUM_PE*32 +: NUM_PE*32];
                mem_write_data_global = mem_write_data_in[i*NUM_PE*32 +: NUM_PE*32];
                mem_write_global      = mem_write_store[i*NUM_PE +: NUM_PE];
            end
        end
    end
endmodule
