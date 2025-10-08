module input_mux #(parameter N = 4, WIDTH = 32)(
    input  [N*WIDTH-1:0] data_in,
    input  [clog2(N)-1:0] select,
    output [WIDTH-1:0] data_out
);
    assign data_out = data_in[select*WIDTH +: WIDTH];
endmodule
