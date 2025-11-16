// MUX 2:1 para seleccion de entradas

module mux2_1(in_1, in_2, sel, data_out);

input      [31:0] in_1;
input      [31:0] in_2;
input             sel;
output reg    [31:0] data_out;

always @(*) begin
        data_out = sel ? in_2 : in_1; 
    end

endmodule