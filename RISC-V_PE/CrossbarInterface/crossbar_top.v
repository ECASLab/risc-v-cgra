module crossbar_top #(parameter N = 4, WIDTH = 32)(
    input clk,
    input rst,
    input  [N*WIDTH-1:0] cluster_out,       // Data from clusters
    input  [N-1:0]       cluster_valid,     // Valid signals from clusters
    output [N-1:0]       cluster_ready,     // Ready signals to clusters
    output [N*WIDTH-1:0] cluster_in,        // Data to clusters
    output [N-1:0]       cluster_in_valid,  // Valid signals to clusters
    input  [N-1:0]       cluster_in_ready   // Ready signals from clusters
);

    wire [N*WIDTH-1:0] crossbar_data_out;
    wire [N*WIDTH-1:0] crossbar_data_in;
    wire [N*clog2(N)-1:0] select_lines;

    // Arbitration per output port
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : arb_block
            wire [N-1:0] requests;
            wire [clog2(N)-1:0] grant;
            wire valid;

            assign requests = cluster_valid; // All clusters may request access

            arbiter #(N) arb_inst (
                .request(requests),
                .grant(grant),
                .valid(valid)
            );

            assign select_lines[i*clog2(N) +: clog2(N)] = grant;
        end
    endgenerate

    // Crossbar routing
    crossbar #(N, WIDTH) xbar_inst (
        .data_out(cluster_out),
        .select(select_lines),
        .data_in(crossbar_data_in)
    );

    assign cluster_in = crossbar_data_in;
    assign cluster_in_valid = cluster_valid; // Simplified: propagate valid
    assign cluster_ready = cluster_in_ready; // Simplified: propagate ready

endmodule
