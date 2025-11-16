module mux3_1 (
    input      [31:0] in_1,
    input      [31:0] in_2,
    input      [31:0] in_3,
    input      [1:0]  sel,
    output reg [31:0] data_out
);
    always @(*) begin
        case(sel)
            2'b00: data_out = in_1; // Select in_1
            2'b01: data_out = in_2; // Select in_2
            2'b10: data_out = in_3; // Select in_3
            default: data_out = 32'b0; // Default case (optional)
        endcase
    end

endmodule