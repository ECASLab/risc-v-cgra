module timeout_monitor #(parameter MAX_COUNT = 1024)(
    input clk,
    input rst,
    input active,
    output reg timeout
);
    reg [$clog2(MAX_COUNT)-1:0] counter;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            timeout <= 0;
        end else if (active) begin
            if (counter == MAX_COUNT - 1)
                timeout <= 1;
            else
                counter <= counter + 1;
        end else begin
            counter <= 0;
            timeout <= 0;
        end
    end
endmodule
