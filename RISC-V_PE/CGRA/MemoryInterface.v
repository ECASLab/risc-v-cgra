module cluster_request_interface #(
    parameter NUM_CLUSTERS = 4,
    parameter NUM_PE = 4
)(
    input [NUM_CLUSTERS*NUM_PE-1:0] mem_read_all,
    input [NUM_CLUSTERS*NUM_PE-1:0] mem_write_all,
    output reg [NUM_CLUSTERS-1:0] req
);

    integer i, j;

    always @(*) begin
        for (i = 0; i < NUM_CLUSTERS; i = i + 1) begin
            req[i] = 0;
            for (j = 0; j < NUM_PE; j = j + 1) begin
                if (mem_read_all[i*NUM_PE + j] || mem_write_all[i*NUM_PE + j]) begin
                    req[i] = 1;
                end
            end
        end
    end
endmodule
