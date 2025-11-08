module cluster_request_interface #(
    parameter NUM_CLUSTERS = 4,
    parameter NUM_PE = 4
)(
    input  [NUM_CLUSTERS*NUM_PE-1:0] mem_read_all,
    input  [NUM_CLUSTERS*NUM_PE-1:0] mem_write_all,
    output reg [NUM_CLUSTERS-1:0] read_req,
    output reg [NUM_CLUSTERS-1:0] write_req
);

    integer i, j;

    always @(*) begin
        // Initialize outputs
        read_req  = 0;
        write_req = 0;

        for (i = 0; i < NUM_CLUSTERS; i = i + 1) begin
            for (j = 0; j < NUM_PE; j = j + 1) begin
                if (mem_read_all[i*NUM_PE + j])
                    read_req[i] = 1;
                if (mem_write_all[i*NUM_PE + j])
                    write_req[i] = 1;
            end
        end
    end

endmodule

