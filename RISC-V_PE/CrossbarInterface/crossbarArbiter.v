module arbiter #(parameter N = 4)(
    input  [N-1:0] request,
    output reg [clog2(N)-1:0] grant,
    output reg valid
);
    integer i;
    always @(*) begin
        valid = 0;
        grant = 0;
        for (i = 0; i < N; i = i + 1) begin
            if (request[i] && !valid) begin
                grant = i[clog2(N)-1:0];
                valid = 1;
            end
        end
    end
endmodule
