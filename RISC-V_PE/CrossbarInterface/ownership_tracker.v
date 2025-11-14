module ownership_tracker #(parameter N = 4)(
    input clk,
    input rst,
    input [clog2(N)-1:0] requester,
    input request_valid,
    input release,
    output reg [clog2(N)-1:0] owner,
    output reg owned
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            owner <= 0;
            owned <= 0;
        end else if (release) begin
            owned <= 0;
        end else if (request_valid && !owned) begin
            owner <= requester;
            owned <= 1;
        end
    end
endmodule
