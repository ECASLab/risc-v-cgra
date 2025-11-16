// 32-bit ALU for CGRA with asynchronous reset
module alu(
    input        clk,      // Clock input
    input        reset,    // Active-high asynchronous reset
    input [31:0] A, B,     // ALU 32-bit Inputs                 
    input [4:0]  ALU_Sel,  // ALU Selection
    output reg [31:0] ALU_Out, // ALU 32-bit Output
    output reg Zero,        // Zero flag when ALU output is 0
    output reg ALUcomplete, // Indicates end of operation
    output reg Cout         // Carry out for adder
);

    integer i;
    reg [31:0] y;

    wire [31:0] add_result, sub_result, mult_result;
    wire add_carry_out, sub_borrow;

    // Instantiate submodules
    RippleCarryAdder adder (
        .A(A),
        .B(B),
        .Cin(1'b0),
        .Sum(add_result),
        .Cout(add_carry_out)
    );
    
    Subtraction subtractor (
        .A(A),
        .B(B),
        .Diff(sub_result),
        .Borrow(sub_borrow)  
    );

    dadda_16_pipelined multiplier (
        .clk(clk),
        .rst(reset),
        .A(A[15:0]),
        .B(B[15:0]),
        .Y_reg(mult_result)
    );

    // Sequential logic with asynchronous reset
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ALU_Out     <= 32'b0;
            ALUcomplete <= 1'b0;
            Cout        <= 1'b0;
            Zero        <= 1'b0;
        end else begin
            // Default values each cycle
            ALU_Out     <= 32'b0;
            ALUcomplete <= 1'b0;
            Cout        <= 1'b0;

            case (ALU_Sel)
                5'b00000: begin // Addition
                    ALU_Out     <= add_result;
                    ALUcomplete <= 1'b1;
                    Cout        <= add_carry_out;
                end
                5'b00001: begin // Subtraction
                    ALU_Out     <= sub_result;
                    ALUcomplete <= 1'b1;
                end
                5'b00010: begin // Multiplication
                    ALU_Out     <= mult_result;
                    ALUcomplete <= (mult_result != 0);
                end
                5'b00011: begin // Division
                    if (B != 0) begin
                        ALU_Out     <= A / B;
                        ALUcomplete <= 1'b1;
                    end else begin
                        ALU_Out     <= 32'hFFFFFFFF;
                        ALUcomplete <= 1'b0;
                    end
                end
                5'b00100: begin // Logical shift left
                    ALU_Out     <= A << B;
                    ALUcomplete <= 1'b1;
                end
                5'b00101: begin // Logical shift right
                    ALU_Out     <= A >> B;
                    ALUcomplete <= 1'b1;
                end
                5'b00110: begin // Compare equal
                    ALU_Out     <= (A == B) ? 32'd1 : 32'd0;
                    ALUcomplete <= 1'b1;
                end
                5'b00111: begin // Rotate right
                    ALU_Out     <= {A[0], A[31:1]};
                    ALUcomplete <= 1'b1;
                end
                5'b01000: begin // AND
                    ALU_Out     <= A & B;
                    ALUcomplete <= 1'b1;
                end
                5'b01001: begin // OR
                    ALU_Out     <= A | B;
                    ALUcomplete <= 1'b1;
                end
                5'b01010: begin // XOR
                    ALU_Out     <= A ^ B;
                    ALUcomplete <= 1'b1;
                end
                5'b01011: begin // Branch less-than
                    ALU_Out     <= (A < B) ? 32'd1 : 32'd0;
                    ALUcomplete <= 1'b1;
                end
                5'b01101: begin // SLTU
                    ALU_Out     <= (A < B) ? 32'd1 : 32'd0;
                    ALUcomplete <= 1'b1;
                end
                5'b01110: begin // SLT (signed)
                    if (A[31] != B[31])
                        ALU_Out <= (A[31] > B[31]) ? 32'd1 : 32'd0;
                    else
                        ALU_Out <= (A < B) ? 32'd1 : 32'd0;
                    ALUcomplete <= 1'b1;
                end
                5'b01111: begin // SRA
                    ALU_Out     <= $signed(A) >>> B;
                    ALUcomplete <= 1'b1;
                end
                5'b10000: begin // Lower byte sign-extended
                    ALU_Out     <= {{24{A[7]}}, A[7:0]};
                    ALUcomplete <= 1'b1;
                end
                5'b10001: begin // Lower halfword sign-extended
                    ALU_Out     <= {{16{A[15]}}, A[15:0]};
                    ALUcomplete <= 1'b1;
                end
                5'b10010: begin // Lower byte unsigned
                    ALU_Out     <= {24'b0, A[7:0]};
                    ALUcomplete <= 1'b1;
                end
                5'b10011: begin // Lower halfword unsigned
                    ALU_Out     <= {16'b0, A[15:0]};
                    ALUcomplete <= 1'b1;
                end
                5'b10100: begin // Entire word
                    ALU_Out     <= A;
                    ALUcomplete <= 1'b1;
                end
                5'b10101: begin // Lower byte sign-extended (B)
                    ALU_Out     <= {{24{B[7]}}, B[7:0]};
                    ALUcomplete <= 1'b1;
                end
                5'b10110: begin // Lower halfword sign-extended (B)
                    ALU_Out     <= {{16{B[15]}}, B[15:0]};
                    ALUcomplete <= 1'b1;
                end
                5'b10111: begin // Lower byte unsigned (B)
                    ALU_Out     <= {24'b0, B[7:0]};
                    ALUcomplete <= 1'b1;
                end
                5'b11000: begin // Lower halfword unsigned (B)
                    ALU_Out     <= {16'b0, B[15:0]};
                    ALUcomplete <= 1'b1;
                end
                5'b11001: begin // Entire word (B)
                    ALU_Out     <= B;
                    ALUcomplete <= 1'b1;
                end
                default: begin
                    ALU_Out     <= 32'b0;
                    ALUcomplete <= 1'b0;
                end
            endcase

            Zero <= (ALU_Out == 32'b0);
        end
    end

endmodule
