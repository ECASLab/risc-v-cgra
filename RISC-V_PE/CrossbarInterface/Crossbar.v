module crossbar #(parameter N = 4, WIDTH = 32)(
    input  [N*WIDTH-1:0] data_out,
    input  [N*clog2(N)-1:0] select,
    output [N*WIDTH-1:0] data_in
);
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : mux
            wire [clog2(N)-1:0] sel = select[i*clog2(N) +: clog2(N)];
            assign data_in[i*WIDTH +: WIDTH] = data_out[sel*WIDTH +: WIDTH];
        end
    endgenerate
endmodule
