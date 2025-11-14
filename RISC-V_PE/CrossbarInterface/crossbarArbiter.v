`include "devs.vh"

module arbiter #(parameter N = 4)(
    input clk,
    input rst,
    input [N-1:0] request,
    output reg [`CLOG2(N)-1:0] grant,
    output reg valid
);

    reg [`CLOG2(N)-1:0] last_grant;
    reg [`CLOG2(N)-1:0] temp_grant;
    reg temp_valid;
    integer i, j;

    always @(*) begin
        temp_valid = 0;
        temp_grant = 0;
        for (i = 1; i <= N; i = i + 1) begin
            j = (last_grant + i) % N;
            if (request[j] && !temp_valid) begin
                temp_grant = j;
                temp_valid = 1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        $display("Valid: %b | grant: %b | Last grant: %b | temp_valid: %b | temp_grant: %b", valid, grant, last_grant, temp_valid, temp_grant);
        if (rst) begin
            last_grant <= 0;
            grant <= 0;
            valid <= 0;
        end else begin
            grant <= temp_grant;
            valid <= temp_valid;
            if (temp_valid)
                last_grant <= temp_grant;
        end
    end


endmodule


