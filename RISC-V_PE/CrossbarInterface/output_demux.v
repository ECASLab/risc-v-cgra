module output_demux #(parameter N = 4, WIDTH = 32)(
    input  [WIDTH-1:0] data_in,
    input  [clog2(N)-1:0] select,
    output [N*WIDTH-1:0] data_out
);
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : demux
            assign data_out[i*WIDTH +: WIDTH] = (select == i) ? data_in : {WIDTH{1'bz}};
        end
    endgenerate
endmodule
