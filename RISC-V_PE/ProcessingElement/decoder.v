// Instruction decoder module

`define DEBUG

module decoder (op, funct3, funct7, rs1, rs2, rd, imm12, immhi, instruction, decodeComplete);

input  [31:0] instruction;
output reg [6:0]  op;
output reg [2:0]  funct3;
output reg [6:0]  funct7;
output reg [4:0]  rs1; //index for register 1 or opperand 1
output reg [4:0]  rs2; //index for register 2 or opperand 2
output reg [4:0]  rd;  //index for the destination register
output reg [11:0] imm12; //immidiate value for I type, S type and B type instructions
output reg [19:0] immhi; //immidiate value for U and J type instructions
output reg        decodeComplete;



always @(*) begin
    // Extract opcode
    op <= instruction [6:0];

    //Default values for outputs
    funct3 <= 3'b000;
    funct7 <= 7'b0000000;
    rs1 <= 5'b00000;
    rs2 <= 5'b00000;
    rd <= 5'b00000;
    imm12 <= 12'b000000000000;
    immhi <= 20'b00000000000000000000;
    decodeComplete <= 0;
    

    case (op)
        7'b0110011 , 7'b1010011: // Type R instruction
            begin
                funct3 <= instruction[14:12];
                funct7 <= instruction[31:25];
                rs1 <= instruction[19:15];
                rs2 <= instruction[24:20];
                rd <= instruction[11:7];
            end

        7'b1101111: // Type J instruction
            begin
                rd <= instruction[11:7];
                immhi <= {instruction[31], instruction[19:12], instruction[20], instruction[30:21]};
            end

        7'b0010111 , 7'b0110111: //Type U instruction
            begin
                rd <= instruction[11:7];
                immhi <= instruction[31:12];
            end

        7'b0100011 , 7'b0100111: //Type S instruction
            begin
                funct3 <= instruction[14:12];
                imm12 <= {instruction[31:25], instruction[11:7]};
                rs1 <= instruction[19:15];
                rs2 <= instruction[24:20];
            end

        7'b1100011: //Type B instruction
            begin
                funct3 <= instruction[14:12];
                rs1 <= instruction[19:15];
                rs2 <= instruction[24:20];
                imm12 <= {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};
            end

        7'b0000011 , 7'b0010011 , 7'b1100111 , 7'b0000111: //Type I instruction
            begin
                funct3 <= instruction[14:12];
                rs1 <= instruction[19:15];
                rd <= instruction[11:7];
                imm12 <= instruction[31:20];
            end

        default: 
            begin
                `ifdef DEBUG
                     $display("This code does not correspond to any valid operation");
                `endif
                //op <= 7'b1111111; // Invalid opcode indicator
            end
    endcase

    decodeComplete <= (op == 7'b0110011 || op == 7'b1010011 || op == 7'b1101111 || op == 7'b0010111 || op == 7'b0100011 || op == 7'b1100011 || op == 7'b0100111 || op == 7'b0000011 || op == 7'b0010011 || op == 7'b1100111 || op == 7'b0000111 || op == 7'b1100011 || op == 7'b0110111);
    

    end

    endmodule






