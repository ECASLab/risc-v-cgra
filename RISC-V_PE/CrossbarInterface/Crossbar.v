module crossbar #(parameter N = 4, WIDTH = 32)(
    input  [N*WIDTH-1:0] result_out,
    input  [N*clog2(N)-1:0] select,
    output [N*WIDTH-1:0] result_in
);
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : mux
            wire [clog2(N)-1:0] sel = select[i*clog2(N) +: clog2(N)];
            assign result_in[i*WIDTH +: WIDTH] = result_out[sel*WIDTH +: WIDTH];
        end
    endgenerate
endmodule
