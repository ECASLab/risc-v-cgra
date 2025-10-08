module mux_control #(parameter N = 4)(
    input  [N-1:0] request,
    output [clog2(N)-1:0] select,
    output valid
);
    arbiter #(N) arb_inst (
        .request(request),
        .grant(select),
        .valid(valid)
    );
endmodule
