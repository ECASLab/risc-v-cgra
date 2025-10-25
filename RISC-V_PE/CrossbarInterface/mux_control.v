`include "crossbarArbiter.v"
`include "devs.vh"

module mux_control #(parameter N = 4, TIMEOUT_CYCLES = 4)(
    input clk,
    input rst,
    input [N-1:0] request,
    input release_sig,                      // Cluster signals it's done
    output reg [SEL_WIDTH-1:0] select,
    output reg valid
);
    localparam SEL_WIDTH = `CLOG2(N);
    localparam TIMEOUT_WIDTH = `CLOG2(TIMEOUT_CYCLES);

    reg [SEL_WIDTH-1:0] current_grant;
    reg [TIMEOUT_WIDTH-1:0] timeout_counter;
    reg holding;
    reg holding_next;

    wire [SEL_WIDTH-1:0] next_grant;
    wire next_valid;

    // Core round-robin arbiter
    arbiter #(N) arb_inst (
        .clk(clk),
        .rst(rst),
        .request(request),
        .grant(next_grant),
        .valid(next_valid)
    );

    always @(posedge clk or posedge rst) begin
        $display("Holding=%b | timeout=%d | select=%d | valid=%b", holding, timeout_counter, select, valid);
        if (rst) begin
            current_grant <= 0;
            timeout_counter <= 0;
            holding <= 0;
            select <= 0;
            valid <= 0;
            holding_next <= 0;
        end else begin
            if (holding_next) begin
                holding <= 1;
                holding_next <= 0;
            end

            if (holding) begin
                timeout_counter <= timeout_counter + 1;
                $display("We entered holding state. Timeout counter: %d", timeout_counter);
                if (release_sig || timeout_counter >= TIMEOUT_CYCLES) begin
                    holding <= 0;
                    holding_next <= 0;
                    timeout_counter <= 0;
                    current_grant <= 0;
                    select <= 0;
                    valid <= 0;
                end else begin
                    select <= current_grant;
                    valid  <= 1;
                end
            end


            if (!holding && next_valid) begin
                current_grant <= next_grant;
                select <= next_grant;
                valid <= 1;
                holding_next <= 1;
                timeout_counter <= 0;
            end else begin
                select <= 0;
                valid <= 0;
            end
            
        end
    end

endmodule
