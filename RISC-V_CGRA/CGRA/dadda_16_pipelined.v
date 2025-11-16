// A - 16 bits , B - 16 bits, Y(output) - 32 bits
// Pipelined version using 8*8 dadda modules

module dadda_16_pipelined(clk, rst, A, B, Y_reg);
    input clk, rst;
    input [15:0] A;
    input [15:0] B;
    output reg [31:0] Y_reg;
    
    wire [31:0] Y;
    
    // Pipeline registers
    reg [15:0] A_reg, B_reg;
    wire [15:0] y11, y12, y21, y22;
    reg [15:0] y11_reg, y12_reg, y21_reg, y22_reg;
    
    // Stage 1 sum and carry
    wire [15:0] s_1, c_1;
    reg [15:0] s_1_reg, c_1_reg;
    
    // Stage 2 carry
    wire [22:0] c_2;
    
    
    // Instantiate 8x8 multipliers (pipelined versions)
    dadda_8_pipelined d1(.clk(clk), .rst(rst), .A(A[7:0]), .B(B[7:0]), .y(y11));
    dadda_8_pipelined d2(.clk(clk), .rst(rst), .A(A[7:0]), .B(B[15:8]), .y(y12));
    dadda_8_pipelined d3(.clk(clk), .rst(rst), .A(A[15:8]), .B(B[7:0]), .y(y21));
    dadda_8_pipelined d4(.clk(clk), .rst(rst), .A(A[15:8]), .B(B[15:8]), .y(y22));
    
    // Pipeline stage 0: Register inputs
    always @(posedge clk) begin
        if (!rst) begin
            A_reg <= 16'b0;
            B_reg <= 16'b0;
        end else begin
            A_reg <= A;
            B_reg <= B;
        end
    end
    
    // Pipeline stage 1: Register 8x8 multiplier outputs
    always @(posedge clk) begin
        if (!rst) begin
            y11_reg <= 16'b0;
            y12_reg <= 16'b0;
            y21_reg <= 16'b0;
            y22_reg <= 16'b0;
        end else begin
            y11_reg <= y11;
            y12_reg <= y12;
            y21_reg <= y21;
            y22_reg <= y22;
        end
    end
    
    // Stage 1 - reducing from 3 to 2 (combinational)
    assign Y[7:0] = y11_reg[7:0];
    
    csa_dadda c_11(.A(y11_reg[8]), .B(y12_reg[0]), .Cin(y21_reg[0]), .Y(s_1[0]), .Cout(c_1[0]));
    assign Y[8] = s_1[0];
    csa_dadda c_12(.A(y11_reg[9]), .B(y12_reg[1]), .Cin(y21_reg[1]), .Y(s_1[1]), .Cout(c_1[1]));
    csa_dadda c_13(.A(y11_reg[10]), .B(y12_reg[2]), .Cin(y21_reg[2]), .Y(s_1[2]), .Cout(c_1[2]));
    csa_dadda c_14(.A(y11_reg[11]), .B(y12_reg[3]), .Cin(y21_reg[3]), .Y(s_1[3]), .Cout(c_1[3]));
    csa_dadda c_15(.A(y11_reg[12]), .B(y12_reg[4]), .Cin(y21_reg[4]), .Y(s_1[4]), .Cout(c_1[4]));
    csa_dadda c_16(.A(y11_reg[13]), .B(y12_reg[5]), .Cin(y21_reg[5]), .Y(s_1[5]), .Cout(c_1[5]));
    csa_dadda c_17(.A(y11_reg[14]), .B(y12_reg[6]), .Cin(y21_reg[6]), .Y(s_1[6]), .Cout(c_1[6]));
    csa_dadda c_18(.A(y11_reg[15]), .B(y12_reg[7]), .Cin(y21_reg[7]), .Y(s_1[7]), .Cout(c_1[7]));
    csa_dadda c_19(.A(y22_reg[0]), .B(y12_reg[8]), .Cin(y21_reg[8]), .Y(s_1[8]), .Cout(c_1[8]));
    csa_dadda c_110(.A(y22_reg[1]), .B(y12_reg[9]), .Cin(y21_reg[9]), .Y(s_1[9]), .Cout(c_1[9]));
    csa_dadda c_111(.A(y22_reg[2]), .B(y12_reg[10]), .Cin(y21_reg[10]), .Y(s_1[10]), .Cout(c_1[10]));
    csa_dadda c_112(.A(y22_reg[3]), .B(y12_reg[11]), .Cin(y21_reg[11]), .Y(s_1[11]), .Cout(c_1[11]));
    csa_dadda c_113(.A(y22_reg[4]), .B(y12_reg[12]), .Cin(y21_reg[12]), .Y(s_1[12]), .Cout(c_1[12]));
    csa_dadda c_114(.A(y22_reg[5]), .B(y12_reg[13]), .Cin(y21_reg[13]), .Y(s_1[13]), .Cout(c_1[13]));
    csa_dadda c_115(.A(y22_reg[6]), .B(y12_reg[14]), .Cin(y21_reg[14]), .Y(s_1[14]), .Cout(c_1[14]));
    csa_dadda c_116(.A(y22_reg[7]), .B(y12_reg[15]), .Cin(y21_reg[15]), .Y(s_1[15]), .Cout(c_1[15]));
    
    // Pipeline stage 2: Register stage 1 results
    always @(posedge clk) begin
        if (!rst) begin
            s_1_reg <= 16'b0;
            c_1_reg <= 16'b0;
        end else begin
            s_1_reg <= s_1;
            c_1_reg <= c_1;
        end
    end
    
    // Stage 2 - reducing from 2 to 1 (combinational)
    HA h1(.a(s_1_reg[1]), .b(c_1_reg[0]), .Sum(Y[9]), .Cout(c_2[0]));
    
    csa_dadda c_22(.A(s_1_reg[2]), .B(c_1_reg[1]), .Cin(c_2[0]), .Y(Y[10]), .Cout(c_2[1]));
    csa_dadda c_23(.A(s_1_reg[3]), .B(c_1_reg[2]), .Cin(c_2[1]), .Y(Y[11]), .Cout(c_2[2]));
    csa_dadda c_24(.A(s_1_reg[4]), .B(c_1_reg[3]), .Cin(c_2[2]), .Y(Y[12]), .Cout(c_2[3]));
    csa_dadda c_25(.A(s_1_reg[5]), .B(c_1_reg[4]), .Cin(c_2[3]), .Y(Y[13]), .Cout(c_2[4]));
    csa_dadda c_26(.A(s_1_reg[6]), .B(c_1_reg[5]), .Cin(c_2[4]), .Y(Y[14]), .Cout(c_2[5]));
    csa_dadda c_27(.A(s_1_reg[7]), .B(c_1_reg[6]), .Cin(c_2[5]), .Y(Y[15]), .Cout(c_2[6]));
    csa_dadda c_28(.A(s_1_reg[8]), .B(c_1_reg[7]), .Cin(c_2[6]), .Y(Y[16]), .Cout(c_2[7]));
    csa_dadda c_29(.A(s_1_reg[9]), .B(c_1_reg[8]), .Cin(c_2[7]), .Y(Y[17]), .Cout(c_2[8]));
    csa_dadda c_210(.A(s_1_reg[10]), .B(c_1_reg[9]), .Cin(c_2[8]), .Y(Y[18]), .Cout(c_2[9]));
    csa_dadda c_211(.A(s_1_reg[11]), .B(c_1_reg[10]), .Cin(c_2[9]), .Y(Y[19]), .Cout(c_2[10]));
    csa_dadda c_212(.A(s_1_reg[12]), .B(c_1_reg[11]), .Cin(c_2[10]), .Y(Y[20]), .Cout(c_2[11]));
    csa_dadda c_213(.A(s_1_reg[13]), .B(c_1_reg[12]), .Cin(c_2[11]), .Y(Y[21]), .Cout(c_2[12]));
    csa_dadda c_214(.A(s_1_reg[14]), .B(c_1_reg[13]), .Cin(c_2[12]), .Y(Y[22]), .Cout(c_2[13]));
    csa_dadda c_215(.A(s_1_reg[15]), .B(c_1_reg[14]), .Cin(c_2[13]), .Y(Y[23]), .Cout(c_2[14]));
    csa_dadda c_216(.A(y22_reg[8]), .B(c_1_reg[15]), .Cin(c_2[14]), .Y(Y[24]), .Cout(c_2[15]));
    
    HA h2(.a(y22_reg[9]), .b(c_2[15]), .Sum(Y[25]), .Cout(c_2[16]));
    HA h3(.a(y22_reg[10]), .b(c_2[16]), .Sum(Y[26]), .Cout(c_2[17]));
    HA h4(.a(y22_reg[11]), .b(c_2[17]), .Sum(Y[27]), .Cout(c_2[18]));
    HA h5(.a(y22_reg[12]), .b(c_2[18]), .Sum(Y[28]), .Cout(c_2[19]));
    HA h6(.a(y22_reg[13]), .b(c_2[19]), .Sum(Y[29]), .Cout(c_2[20]));
    HA h7(.a(y22_reg[14]), .b(c_2[20]), .Sum(Y[30]), .Cout(c_2[21]));
    HA h8(.a(y22_reg[15]), .b(c_2[21]), .Sum(Y[31]), .Cout(c_2[22]));
    
    // Pipeline stage 3: Register final output
    always @(posedge clk) begin
        if (!rst) begin
            Y_reg <= 32'b0;
        end else begin
            Y_reg <= Y;
        end
    end
endmodule