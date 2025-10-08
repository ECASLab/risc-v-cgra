// Full adder module for 32 bit data

module FullAdder (
    input A, B, Cin, //Single bit inputs
    output wire Sum, Cout //Single bit outputs
);

    assign Sum = A ^ B ^ Cin;
    assign Cout = (A & B) | (B & Cin) | (A & Cin);
endmodule

module RippleCarryAdder (
    input [31:0] A, B,
    input Cin,
    output [31:0] Sum,
    output Cout
);
    wire [31:0] Carry;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin: FA
            if (i == 0) begin
                FullAdder fa (
                    .A(A[i]),
                    .B(B[i]),
                    .Cin(Cin),
                    .Sum(Sum[i]),
                    .Cout(Carry[i])
                );
            end else begin
                FullAdder fa (
                    .A(A[i]),
                    .B(B[i]),
                    .Cin(Carry[i-1]),
                    .Sum(Sum[i]),
                    .Cout(Carry[i])
                );
            end
        end
    endgenerate

    assign Cout = Carry[31];
endmodule




