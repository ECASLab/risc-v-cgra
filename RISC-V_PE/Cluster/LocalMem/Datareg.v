module DataRegister (
    input             clock,
    input             r_enable,
    input      [31:0] data_in,
    input             reset, // Add reset signal
    output reg [31:0] data_out
);
    

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            data_out <= 32'b0; // Reset the output to 0
        end else if (r_enable) begin
            data_out <= data_in; // Load data on enable
        end
    end

endmodule
