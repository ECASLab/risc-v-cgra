// Subtraction module
module Subtraction (
    input [31:0] A, B,
    output wire [31:0] Diff,
    output Borrow
);

    wire [31:0] B_neg;
    wire Cout;

    assign B_neg = ~B + 32'b1; //Invert B and add 1
    RippleCarryAdder rca (.A(A), .B(B_neg), .Cin(1'b0), .Sum(Diff), .Cout(Borrow));
endmodule
