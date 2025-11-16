module decoder (
    input  [31:0] instruction,
    output reg [6:0]  op,
    output reg [2:0]  funct3,
    output reg [6:0]  funct7,
    output reg [4:0]  rs1,
    output reg [4:0]  rs2,
    output reg [4:0]  rd,
    output reg [11:0] imm12,
    output reg [19:0] immhi,
    output reg        decodeComplete
);

    reg [127:0] op_type;

    always @(*) begin
        // Extract opcode
        op = instruction[6:0];

        // Default values
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        rs1 = 5'b00000;
        rs2 = 5'b00000;
        rd = 5'b00000;
        imm12 = 12'b0;
        immhi = 20'b0;
        decodeComplete = 0;
        op_type = "UNKNOWN";

        case (op)
            7'b0110011, 7'b1010011: begin // R-type
                funct3 = instruction[14:12];
                funct7 = instruction[31:25];
                rs1 = instruction[19:15];
                rs2 = instruction[24:20];
                rd  = instruction[11:7];
                op_type = "ALU-R";
            end
            7'b1101111: begin // J-type
                rd = instruction[11:7];
                immhi = {instruction[31], instruction[19:12], instruction[20], instruction[30:21]};
                op_type = "JUMP-J";
            end
            7'b0010111, 7'b0110111: begin // U-type
                rd = instruction[11:7];
                immhi = instruction[31:12];
                op_type = "U-TYPE";
            end
            7'b0100011, 7'b0100111: begin // S-type
                funct3 = instruction[14:12];
                imm12 = {instruction[31:25], instruction[11:7]};
                rs1 = instruction[19:15];
                rs2 = instruction[24:20];
                op_type = "STORE-S";
            end
            7'b1100011: begin // B-type
                funct3 = instruction[14:12];
                rs1 = instruction[19:15];
                rs2 = instruction[24:20];
                imm12 = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};
                op_type = "BRANCH";
            end
            7'b0000011, 7'b0010011, 7'b1100111, 7'b0000111: begin // I-type
                funct3 = instruction[14:12];
                rs1 = instruction[19:15];
                rd = instruction[11:7];
                imm12 = instruction[31:20];
                if (op == 7'b0000011) op_type = "LOAD-I";
                else if (op == 7'b0010011) op_type = "ALU-I";
                else if (op == 7'b1100111) op_type = "JUMP-I";
                else if (op == 7'b0000111) op_type = "LOAD-DF";
            end
            default: begin
                op = 7'b1111111;
                op_type = "INVALID";
            end
        endcase

        decodeComplete = (op != 7'b1111111);

        // Display decoded fields
        $display("Instruction: %h", instruction);
        $display("  op: %b (%s)", op, op_type);
        $display("  funct3: %b, funct7: %b", funct3, funct7);
        $display("  rs1: x%0d, rs2: x%0d, rd: x%0d", rs1, rs2, rd);
        $display("  imm12: %h, immhi: %h", imm12, immhi);
        $display("--------------------------------------------------");
    end

endmodule
