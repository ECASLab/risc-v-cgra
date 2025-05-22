//Modelo de la ALU de 32 bits para procesamiento de las funciones
//`define DEBUG

`include "Subtraction.v"

module alu(
           input        clk,      // Clock input
           input        reset,
           input [31:0] A, B,     // ALU 32-bit Inputs                 
           input [4:0]  ALU_Sel,  // ALU Selection
           output reg [31:0] ALU_Out, // ALU 32-bit Output
           output reg Zero,        // Zero flag when ALU output is 0
           output reg ALUcomplete,  // Indicates end of operation
           output reg Cout          // Value of carry out for adder
    );
    integer i;
    reg [31:0] y;
    wire [32:0] tmp;

    wire [31:0] add_result, sub_result;
    wire add_carry_out, sub_borrow;

RippleCarryAdder adder (
    .A(A),
    .B(B),
    .Cin(1'b0),      // No carry-in for simple addition
    .Sum(add_result),
    .Cout(add_carry_out)
);
    
Subtraction subtractor (
    .A(A),
    .B(B),
    .Diff(sub_result),
    .Borrow(sub_borrow)  
);

    always @(posedge clk or reset) begin
         if (reset)
         begin
            ALUcomplete = 0;
            ALU_Out = 0;
            Cout = 0;
            Zero = 0;
         end
        //ALUcomplete <= 0; // Indicates operation is in progress
        ALU_Out <= 0;
        case (ALU_Sel)
            5'b00000: // Addition
            begin
               ALU_Out <= add_result;
               ALUcomplete <= 1;
               Cout <= add_carry_out;
            end
            5'b00001: // Subtraction
            begin
               ALU_Out <= sub_result;
               ALUcomplete <= 1;
            end
            5'b00010: // Multiplication
            begin
               ALU_Out <= A[15:0] * B[15:0];
               ALUcomplete <= 1;
            end
            5'b00011: // Division
            begin
               if (B != 0) begin
                   ALU_Out <= A / B;
                   ALUcomplete <= 1;
               end else begin
                  `ifdef DEBUG
                     $display("Error: Division by zero at time %t", $time);
                  `endif
                  ALU_Out <= 32'hFFFFFFFF; // Default error value
                  ALUcomplete <= 0;
               end
            end
            5'b00100: // Logical shift left
            begin
               ALU_Out <= A << B;
               ALUcomplete <= 1;
            end
            5'b00101: // Logical shift right
            begin
               ALU_Out <= A >> B;
               ALUcomplete <= 1;
            end
            5'b00110: // Compare if equal
            begin
               if (A == B)
               begin
                  ALU_Out <= 32'b00000000000000000000000000000001;;
                  ALUcomplete <= 1;
               end
               else
               begin
                  ALU_Out <= 32'b00000000000000000000000000000000;;
                  ALUcomplete <= 1;
               end
            end
            5'b00111: // Rotate right
            begin
               ALU_Out <= {A[0], A[31:1]};
               ALUcomplete <= 1;
            end
            5'b01000: // Logical and 
            begin
               ALU_Out <= A & B;
               ALUcomplete <= 1;
            end
            5'b01001: // Logical or
            begin
               ALU_Out <= A | B;
               ALUcomplete <= 1;
            end
            5'b01010: // Logical xor 
            begin
               ALU_Out <= A ^ B;
               ALUcomplete <= 1;
            end
            5'b01011: // Logical nor
            begin
               ALU_Out <= ~(A | B);
               ALUcomplete <= 1;
            end
            5'b01100: // Logical nand 
            begin
               ALU_Out <= ~(A & B);
               ALUcomplete <= 1;
            end
            5'b01101: // SLTU
            begin
               ALU_Out <= (A < B) ? 1 : 0;
               ALUcomplete <= 1;
            end
            5'b01110: // Set on less than
                begin // SLT
                    if (A[31] != B[31]) begin
                        ALU_Out <= (A[31] > B[31]) ? 1 : 0;
                        ALUcomplete <= 1;
                    end else begin
                        ALU_Out <= (A < B) ? 1 : 0;
                        ALUcomplete <= 1;
                    end
                end
            5'b01111: // SRA shift right arithmetic   
                begin
                     y = A;
				         for (i = B; i > 0; i = i - 1) 
                     begin
					         y = {y[31],y[31:1]};
				         end
				         ALU_Out <= y;
                     ALUcomplete <= 1;
               end
            5'b10000: // Take lower byte sign extended
                begin
                   if (A[7] == 1) begin
                      ALU_Out <= {24'b111111111111111111111111, A[7:0]};
                      ALUcomplete <= 1;
                   end else begin
                      ALU_Out <= {24'b0, A[7:0]};
                      ALUcomplete <= 1;
                   end
                end
            5'b10001: // Take lower half word sign extended
                begin
                   if (A[15] == 1) begin
                      ALU_Out <= {16'b1111111111111111, A[15:0]};
                      ALUcomplete <= 1;
                   end else begin
                      ALU_Out <= {16'b0, A[15:0]};
                      ALUcomplete <= 1;
                   end
                end
            5'b10010: // Take lower byte unsigned
                begin
                   ALU_Out <= {24'b0, A[7:0]};
                   ALUcomplete <= 1;
                end
            5'b10011: // Take lower half word unsigned
                begin
                   ALU_Out <= {16'b0, A[15:0]};
                   ALUcomplete <= 1;
                end 
            5'b10100: // Take entire word
                begin
                   ALU_Out <= A;
                   ALUcomplete <= 1;
                end 
            5'b10101: // Take lower byte sign extended with B operand
                begin
                   if (B[7] == 1) begin
                      ALU_Out <= {24'b111111111111111111111111, B[7:0]};
                      ALUcomplete <= 1;
                   end else begin
                      ALU_Out <= {24'b0, B[7:0]};
                      ALUcomplete <= 1;
                   end
                end
            5'b10110: // Take lower half word sign extended with B operand
                begin
                   if (B[15] == 1) begin
                      ALU_Out <= {16'b1111111111111111, B[15:0]};
                      ALUcomplete <= 1;
                   end else begin
                      ALU_Out <= {16'b0, B[15:0]};
                      ALUcomplete <= 1;
                   end
                end
            5'b10111: // Take lower byte unsigned with B operand
                begin
                   ALU_Out <= {24'b0, B[7:0]};
                   ALUcomplete <= 1;
                end
            5'b11000: // Take lower half word unsigned with B operand
                begin
                   ALU_Out <= {16'b0, B[15:0]};
                   ALUcomplete <= 1;
                end 
            5'b11001: // Take entire word with B operand
                begin
                   ALU_Out <= B;
                   ALUcomplete <= 1;
                end 
            5'b11111: // Default case
                begin
                   ALU_Out <= 32'b0;
                   ALUcomplete <= 0;
                end
            default: ALU_Out <= 32'b0;
        endcase

        Zero <= (ALU_Out == 0) ? 1 : 0;
    end

endmodule
