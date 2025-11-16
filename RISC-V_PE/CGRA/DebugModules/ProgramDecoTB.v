`include "ProgramDeco.v"

module tb_decoder;

    reg [31:0] program_mem [0:1023]; // Up to 1024 instructions
    reg [31:0] instruction;
    wire [6:0] op;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [4:0] rs1, rs2, rd;
    wire [11:0] imm12;
    wire [19:0] immhi;
    wire decodeComplete;

    decoder uut (
        .instruction(instruction),
        .op(op),
        .funct3(funct3),
        .funct7(funct7),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm12(imm12),
        .immhi(immhi),
        .decodeComplete(decodeComplete)
    );

    integer i;

    initial begin
        $display("=== Starting Instruction Decode Simulation ===");
        $readmemh("instance_ESTATICO.hex", program_mem);

        for (i = 0; i < 889; i = i + 1) begin
            instruction = program_mem[i];
            #10; // Wait for decode
        end

        $display("=== Simulation Complete ===");
        $finish;
    end

endmodule
