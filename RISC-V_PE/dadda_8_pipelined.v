// dadda multiplier
// A - 8 bits , B - 8bits, y(output) - 16bits

module dadda_8_pipelined(clk, rst, A, B, y);
    
    input clk;
    input rst;
    input [7:0] A;
    input [7:0] B;
    output wire [15:0] y;
    wire  gen_pp [0:7][7:0];
// stage-1 sum and carry
    wire [0:5]s1,c1;
// stage-2 sum and carry
    wire [0:13]s2,c2;   
// stage-3 sum and carry
    wire [0:9]s3,c3;
// stage-4 sum and carry
    wire [0:11]s4,c4;
// stage-5 sum and carry
    wire [0:13]s5,c5;

// Pipes:

// Partial product drag pipes:
reg [0:14] s1_pp_drag_pipe_1;
reg [0:27] s2_pp_drag_pipe_1, s2_pp_drag_pipe_2;
reg [0:6] s3_pp_drag_pipe_1, s3_pp_drag_pipe_2, s3_pp_drag_pipe_3;
reg [0:8] s4_pp_drag_pipe_1, s4_pp_drag_pipe_2, s4_pp_drag_pipe_3, s4_pp_drag_pipe_4;
reg [0:4] s5_pp_drag_pipe_1, s5_pp_drag_pipe_2, s5_pp_drag_pipe_3, s5_pp_drag_pipe_4, s5_pp_drag_pipe_5;

// Sum stages output pipes 

reg [0:5] s1_pipe,c1_pipe;
reg [0:13] s2_pipe,c2_pipe;
reg [0:13] s2_drag_pipe, c2_drag_pipe;
reg [0:9] s3_pipe, c3_pipe;
reg [0:11] s4_pipe, c4_pipe;


// generating partial products 
genvar i;
genvar j;

for(i = 0; i<8; i=i+1)begin

   for(j = 0; j<8;j = j+1)begin
      assign gen_pp[i][j] = A[j]*B[i];
end
end

//Reduction by stages.
// di_values = 2,3,4,6,8,13...


//Stage 1 - reducing fom 8 to 6  


    HA h1(.a(s1_pp_drag_pipe_1[14]),.b(s1_pp_drag_pipe_1[13]),.Sum(s1[0]),.Cout(c1[0]));
    HA h2(.a(s1_pp_drag_pipe_1[12]),.b(s1_pp_drag_pipe_1[11]),.Sum(s1[2]),.Cout(c1[2]));
    HA h3(.a(s1_pp_drag_pipe_1[10]),.b(s1_pp_drag_pipe_1[9]),.Sum(s1[4]),.Cout(c1[4]));

    csa_dadda c11(.A(s1_pp_drag_pipe_1[8]),.B(s1_pp_drag_pipe_1[7]),.Cin(s1_pp_drag_pipe_1[6]),.Y(s1[1]),.Cout(c1[1]));
    csa_dadda c12(.A(s1_pp_drag_pipe_1[5]),.B(s1_pp_drag_pipe_1[4]),.Cin(s1_pp_drag_pipe_1[3]),.Y(s1[3]),.Cout(c1[3])); 
    csa_dadda c13(.A(s1_pp_drag_pipe_1[2]),.B(s1_pp_drag_pipe_1[1]),.Cin(s1_pp_drag_pipe_1[0]),.Y(s1[5]),.Cout(c1[5]));
    
// Stage 2 - reducing from 6 to 4 (using pipelined inputs and last pipe for each stage)
    HA h4(.a(s2_pp_drag_pipe_2[27]),.b(s2_pp_drag_pipe_2[26]),.Sum(s2[0]),.Cout(c2[0]));
    HA h5(.a(s2_pp_drag_pipe_2[25]),.b(s2_pp_drag_pipe_2[24]),.Sum(s2[2]),.Cout(c2[2]));

    csa_dadda c21(.A(s2_pp_drag_pipe_2[23]),.B(s2_pp_drag_pipe_2[22]),.Cin(s2_pp_drag_pipe_2[21]),.Y(s2[1]),.Cout(c2[1]));
    csa_dadda c22(.A(s1_pipe[0]),.B(s2_pp_drag_pipe_2[1]),.Cin(s2_pp_drag_pipe_2[0]),.Y(s2[3]),.Cout(c2[3]));
    csa_dadda c23(.A(s2_pp_drag_pipe_2[20]),.B(s2_pp_drag_pipe_2[19]),.Cin(s2_pp_drag_pipe_2[18]),.Y(s2[4]),.Cout(c2[4]));
    csa_dadda c24(.A(s1_pipe[1]),.B(s1_pipe[2]),.Cin(c1_pipe[0]),.Y(s2[5]),.Cout(c2[5]));
    csa_dadda c25(.A(s2_pp_drag_pipe_2[17]),.B(s2_pp_drag_pipe_2[16]),.Cin(s2_pp_drag_pipe_2[15]),.Y(s2[6]),.Cout(c2[6]));
    csa_dadda c26(.A(s1_pipe[3]),.B(s1_pipe[4]),.Cin(c1_pipe[1]),.Y(s2[7]),.Cout(c2[7]));
    csa_dadda c27(.A(c1_pipe[2]),.B(s2_pp_drag_pipe_2[14]),.Cin(s2_pp_drag_pipe_2[13]),.Y(s2[8]),.Cout(c2[8]));
    csa_dadda c28(.A(s1_pipe[5]),.B(c1_pipe[3]),.Cin(c1_pipe[4]),.Y(s2[9]),.Cout(c2[9]));
    csa_dadda c29(.A(s2_pp_drag_pipe_2[12]),.B(s2_pp_drag_pipe_2[11]),.Cin(s2_pp_drag_pipe_2[10]),.Y(s2[10]),.Cout(c2[10]));
    csa_dadda c210(.A(s2_pp_drag_pipe_2[9]),.B(c1_pipe[5]),.Cin(s2_pp_drag_pipe_2[8]),.Y(s2[11]),.Cout(c2[11]));
    csa_dadda c211(.A(s2_pp_drag_pipe_2[7]),.B(s2_pp_drag_pipe_2[6]),.Cin(s2_pp_drag_pipe_2[5]),.Y(s2[12]),.Cout(c2[12]));
    csa_dadda c212(.A(s2_pp_drag_pipe_2[4]),.B(s2_pp_drag_pipe_2[3]),.Cin(s2_pp_drag_pipe_2[2]),.Y(s2[13]),.Cout(c2[13]));

// Stage 3 - reducing from 4 to 3 (using pipelined inputs and last pipe for each stage)
    HA h6(.a(s3_pp_drag_pipe_3[6]),.b(s3_pp_drag_pipe_3[5]),.Sum(s3[0]),.Cout(c3[0]));

    csa_dadda c31(.A(s2_pipe[0]),.B(s3_pp_drag_pipe_3[4]),.Cin(s3_pp_drag_pipe_3[3]),.Y(s3[1]),.Cout(c3[1]));
    csa_dadda c32(.A(s2_pipe[1]),.B(s2_pipe[2]),.Cin(c2_pipe[0]),.Y(s3[2]),.Cout(c3[2]));
    csa_dadda c33(.A(c2_pipe[1]),.B(c2_pipe[2]),.Cin(s2_pipe[3]),.Y(s3[3]),.Cout(c3[3]));
    csa_dadda c34(.A(c2_pipe[3]),.B(c2_pipe[4]),.Cin(s2_pipe[5]),.Y(s3[4]),.Cout(c3[4]));
    csa_dadda c35(.A(c2_pipe[5]),.B(c2_pipe[6]),.Cin(s2_pipe[7]),.Y(s3[5]),.Cout(c3[5]));
    csa_dadda c36(.A(c2_pipe[7]),.B(c2_pipe[8]),.Cin(s2_pipe[9]),.Y(s3[6]),.Cout(c3[6]));
    csa_dadda c37(.A(c2_pipe[9]),.B(c2_pipe[10]),.Cin(s2_pipe[11]),.Y(s3[7]),.Cout(c3[7]));
    csa_dadda c38(.A(c2_pipe[11]),.B(c2_pipe[12]),.Cin(s2_pipe[13]),.Y(s3[8]),.Cout(c3[8]));
    csa_dadda c39(.A(s3_pp_drag_pipe_3[2]),.B(s3_pp_drag_pipe_3[1]),.Cin(s3_pp_drag_pipe_3[0]),.Y(s3[9]),.Cout(c3[9]));

// Stage 4 - reducing from 3 to 2 (using pipelined inputs and last pipe for each stage)
    HA h7(.a(s4_pp_drag_pipe_4[8]),.b(s4_pp_drag_pipe_4[7]),.Sum(s4[0]),.Cout(c4[0]));

    csa_dadda c41(.A(s3_pipe[0]),.B(s4_pp_drag_pipe_4[6]),.Cin(s4_pp_drag_pipe_4[5]),.Y(s4[1]),.Cout(c4[1]));
    csa_dadda c42(.A(c3_pipe[0]),.B(s3_pipe[1]),.Cin(s4_pp_drag_pipe_4[4]),.Y(s4[2]),.Cout(c4[2]));
    csa_dadda c43(.A(c3_pipe[1]),.B(s3_pipe[2]),.Cin(s4_pp_drag_pipe_4[3]),.Y(s4[3]),.Cout(c4[3]));
    csa_dadda c44(.A(c3_pipe[2]),.B(s3_pipe[3]),.Cin(s2_drag_pipe[4]),.Y(s4[4]),.Cout(c4[4]));
    csa_dadda c45(.A(c3_pipe[3]),.B(s3_pipe[4]),.Cin(s2_drag_pipe[6]),.Y(s4[5]),.Cout(c4[5]));
    csa_dadda c46(.A(c3_pipe[4]),.B(s3_pipe[5]),.Cin(s2_drag_pipe[8]),.Y(s4[6]),.Cout(c4[6]));
    csa_dadda c47(.A(c3_pipe[5]),.B(s3_pipe[6]),.Cin(s2_drag_pipe[10]),.Y(s4[7]),.Cout(c4[7]));
    csa_dadda c48(.A(c3_pipe[6]),.B(s3_pipe[7]),.Cin(s2_drag_pipe[12]),.Y(s4[8]),.Cout(c4[8]));
    csa_dadda c49(.A(c3_pipe[7]),.B(s3_pipe[8]),.Cin(s4_pp_drag_pipe_4[2]),.Y(s4[9]),.Cout(c4[9]));
    csa_dadda c410(.A(c3_pipe[8]),.B(s3_pipe[9]),.Cin(c2_drag_pipe[13]),.Y(s4[10]),.Cout(c4[10]));
    csa_dadda c411(.A(c3_pipe[9]),.B(s4_pp_drag_pipe_4[1]),.Cin(s4_pp_drag_pipe_4[0]),.Y(s4[11]),.Cout(c4[11]));

// Stage 5 - reducing from 2 to 1 (using pipelined inputs and last pipe for each stage)
    HA h8(.a(s5_pp_drag_pipe_5[4]),.b(s5_pp_drag_pipe_5[3]),.Sum(y[1]),.Cout(c5[0]));

    csa_dadda c51(.A(s4_pipe[0]),.B(s5_pp_drag_pipe_5[2]),.Cin(c5[0]),.Y(y[2]),.Cout(c5[1]));
    csa_dadda c52(.A(c4_pipe[0]),.B(s4_pipe[1]),.Cin(c5[1]),.Y(y[3]),.Cout(c5[2]));
    csa_dadda c54(.A(c4_pipe[1]),.B(s4_pipe[2]),.Cin(c5[2]),.Y(y[4]),.Cout(c5[3]));
    csa_dadda c55(.A(c4_pipe[2]),.B(s4_pipe[3]),.Cin(c5[3]),.Y(y[5]),.Cout(c5[4]));
    csa_dadda c56(.A(c4_pipe[3]),.B(s4_pipe[4]),.Cin(c5[4]),.Y(y[6]),.Cout(c5[5]));
    csa_dadda c57(.A(c4_pipe[4]),.B(s4_pipe[5]),.Cin(c5[5]),.Y(y[7]),.Cout(c5[6]));
    csa_dadda c58(.A(c4_pipe[5]),.B(s4_pipe[6]),.Cin(c5[6]),.Y(y[8]),.Cout(c5[7]));
    csa_dadda c59(.A(c4_pipe[6]),.B(s4_pipe[7]),.Cin(c5[7]),.Y(y[9]),.Cout(c5[8]));
    csa_dadda c510(.A(c4_pipe[7]),.B(s4_pipe[8]),.Cin(c5[8]),.Y(y[10]),.Cout(c5[9]));
    csa_dadda c511(.A(c4_pipe[8]),.B(s4_pipe[9]),.Cin(c5[9]),.Y(y[11]),.Cout(c5[10]));
    csa_dadda c512(.A(c4_pipe[9]),.B(s4_pipe[10]),.Cin(c5[10]),.Y(y[12]),.Cout(c5[11]));
    csa_dadda c513(.A(c4_pipe[10]),.B(s4_pipe[11]),.Cin(c5[11]),.Y(y[13]),.Cout(c5[12]));
    csa_dadda c514(.A(c4_pipe[11]),.B(s5_pp_drag_pipe_5[1]),.Cin(c5[12]),.Y(y[14]),.Cout(c5[13]));

    assign y[0] = s5_pp_drag_pipe_5[0];
    assign y[15] = c5[13];
    
// First stage pipeline always block with reset
always @(posedge clk) begin
    if (!rst) begin
        s1_pp_drag_pipe_1 <= 15'b0;
        s1_pipe <= 6'b0;
        c1_pipe <= 6'b0;
    end else begin
        // First pipe captures partial products
        s1_pp_drag_pipe_1[14] <= gen_pp[6][0];  // h1.a
        s1_pp_drag_pipe_1[13] <= gen_pp[5][1];  // h1.b
        s1_pp_drag_pipe_1[12] <= gen_pp[4][3];  // h2.a
        s1_pp_drag_pipe_1[11] <= gen_pp[3][4];  // h2.b
        s1_pp_drag_pipe_1[10] <= gen_pp[4][4];  // h3.a
        s1_pp_drag_pipe_1[9]  <= gen_pp[3][5];  // h3.b
        s1_pp_drag_pipe_1[8]  <= gen_pp[7][0];  // c11.A
        s1_pp_drag_pipe_1[7]  <= gen_pp[6][1];  // c11.B
        s1_pp_drag_pipe_1[6]  <= gen_pp[5][2];  // c11.Cin
        s1_pp_drag_pipe_1[5]  <= gen_pp[7][1];  // c12.A
        s1_pp_drag_pipe_1[4]  <= gen_pp[6][2];  // c12.B
        s1_pp_drag_pipe_1[3]  <= gen_pp[5][3];  // c12.Cin
        s1_pp_drag_pipe_1[2]  <= gen_pp[7][2];  // c13.A
        s1_pp_drag_pipe_1[1]  <= gen_pp[6][3];  // c13.B
        s1_pp_drag_pipe_1[0]  <= gen_pp[5][4];  // c13.Cin
        
        s1_pipe <= s1;
        c1_pipe <= c1;
    end
end

// Second stage pipeline always block with reset
always @(posedge clk) begin
    if (!rst) begin
        s2_pp_drag_pipe_1 <= 28'b0;
        s2_pp_drag_pipe_2 <= 28'b0;
        s2_pipe <= 14'b0;
        c2_pipe <= 14'b0;
    end else begin
        // First pipe captures partial products
        s2_pp_drag_pipe_1[27] <= gen_pp[4][0];
        s2_pp_drag_pipe_1[26] <= gen_pp[3][1];
        s2_pp_drag_pipe_1[25] <= gen_pp[2][3];
        s2_pp_drag_pipe_1[24] <= gen_pp[1][4];
        s2_pp_drag_pipe_1[23] <= gen_pp[5][0];
        s2_pp_drag_pipe_1[22] <= gen_pp[4][1];
        s2_pp_drag_pipe_1[21] <= gen_pp[3][2];
        s2_pp_drag_pipe_1[20] <= gen_pp[2][4];
        s2_pp_drag_pipe_1[19] <= gen_pp[1][5];
        s2_pp_drag_pipe_1[18] <= gen_pp[0][6];
        s2_pp_drag_pipe_1[17] <= gen_pp[2][5];
        s2_pp_drag_pipe_1[16] <= gen_pp[1][6];
        s2_pp_drag_pipe_1[15] <= gen_pp[0][7];
        s2_pp_drag_pipe_1[14] <= gen_pp[2][6];
        s2_pp_drag_pipe_1[13] <= gen_pp[1][7];
        s2_pp_drag_pipe_1[12] <= gen_pp[4][5];
        s2_pp_drag_pipe_1[11] <= gen_pp[3][6];
        s2_pp_drag_pipe_1[10] <= gen_pp[2][7];
        s2_pp_drag_pipe_1[9]  <= gen_pp[7][3];
        s2_pp_drag_pipe_1[8]  <= gen_pp[6][4];
        s2_pp_drag_pipe_1[7]  <= gen_pp[5][5];
        s2_pp_drag_pipe_1[6]  <= gen_pp[4][6];
        s2_pp_drag_pipe_1[5]  <= gen_pp[3][7];
        s2_pp_drag_pipe_1[4]  <= gen_pp[7][4];
        s2_pp_drag_pipe_1[3]  <= gen_pp[6][5];
        s2_pp_drag_pipe_1[2]  <= gen_pp[5][6];
        s2_pp_drag_pipe_1[1]  <= gen_pp[4][2];
        s2_pp_drag_pipe_1[0]  <= gen_pp[3][3];
        
        // Second pipe takes values from first pipe
        s2_pp_drag_pipe_2 <= s2_pp_drag_pipe_1;
        
        s2_pipe <= s2;
        c2_pipe <= c2;
    end
end

// Third stage pipeline always block with reset
always @(posedge clk) begin
    if (!rst) begin
        s3_pp_drag_pipe_1 <= 7'b0000000;
        s3_pp_drag_pipe_2 <= 7'b0000000;
        s3_pp_drag_pipe_3 <= 7'b0000000;
        s3_pipe <= 10'b0000000000;
        c3_pipe <= 10'b0000000000;
    end else begin
        // First pipe captures partial products
        s3_pp_drag_pipe_1[6] <= gen_pp[3][0];
        s3_pp_drag_pipe_1[5] <= gen_pp[2][1];
        s3_pp_drag_pipe_1[4] <= gen_pp[2][2];
        s3_pp_drag_pipe_1[3] <= gen_pp[1][3];
        s3_pp_drag_pipe_1[2] <= gen_pp[7][5];
        s3_pp_drag_pipe_1[1] <= gen_pp[6][6];
        s3_pp_drag_pipe_1[0] <= gen_pp[5][7];
        
        // Second pipe takes values from first pipe
        s3_pp_drag_pipe_2 <= s3_pp_drag_pipe_1;
        
        // Third pipe takes values from second pipe
        s3_pp_drag_pipe_3 <= s3_pp_drag_pipe_2;
        
        s3_pipe <= s3;
        c3_pipe <= c3;


    end
end

// Fourth stage pipeline always block with reset
always @(posedge clk) begin
    if (!rst) begin
        s4_pp_drag_pipe_1 <= 8'b00000000;
        s4_pp_drag_pipe_2 <= 8'b00000000;
        s4_pp_drag_pipe_3 <= 8'b00000000;
        s4_pp_drag_pipe_4 <= 8'b00000000;
        s4_pipe <= 12'b000000000000;
        c4_pipe <= 12'b000000000000;
        s2_drag_pipe <= 14'b0;
        c2_drag_pipe <= 14'b0;
    end else begin
        // First pipe captures partial products
        s4_pp_drag_pipe_1[8] <= gen_pp[2][0];
        s4_pp_drag_pipe_1[7] <= gen_pp[1][1];
        s4_pp_drag_pipe_1[6] <= gen_pp[1][2];
        s4_pp_drag_pipe_1[5] <= gen_pp[0][3];
        s4_pp_drag_pipe_1[4] <= gen_pp[0][4];
        s4_pp_drag_pipe_1[3] <= gen_pp[0][5];
        s4_pp_drag_pipe_1[2] <= gen_pp[4][7];
        s4_pp_drag_pipe_1[1] <= gen_pp[7][6];
        s4_pp_drag_pipe_1[0] <= gen_pp[6][7];
        
        // Second pipe takes values from first pipe
        s4_pp_drag_pipe_2 <= s4_pp_drag_pipe_1;
        
        // Third pipe takes values from second pipe
        s4_pp_drag_pipe_3 <= s4_pp_drag_pipe_2;
        
        // Fourth pipe takes values from third pipe
        s4_pp_drag_pipe_4 <= s4_pp_drag_pipe_3;
        
        s4_pipe <= s4;
        c4_pipe <= c4;

        s2_drag_pipe <= s2_pipe;
        c2_drag_pipe <= c2_pipe;

    end
end

// Fifth stage pipeline always block with reset
always @(posedge clk) begin
    if (!rst) begin
        s5_pp_drag_pipe_1 <= 5'b00000;
        s5_pp_drag_pipe_2 <= 5'b00000;
        s5_pp_drag_pipe_3 <= 5'b00000;
        s5_pp_drag_pipe_4 <= 5'b00000;
        s5_pp_drag_pipe_5 <= 5'b00000;
        s5_pipe <= 14'b00000000000000;
        c5_pipe <= 14'b00000000000000;
    end else begin
        // First pipe captures partial products
        s5_pp_drag_pipe_1[4] <= gen_pp[1][0];
        s5_pp_drag_pipe_1[3] <= gen_pp[0][1];
        s5_pp_drag_pipe_1[2] <= gen_pp[0][2];
        s5_pp_drag_pipe_1[1] <= gen_pp[7][7];
        s5_pp_drag_pipe_1[0] <= gen_pp[0][0];
        
        // Second pipe takes values from first pipe
        s5_pp_drag_pipe_2 <= s5_pp_drag_pipe_1;
        
        // Third pipe takes values from second pipe
        s5_pp_drag_pipe_3 <= s5_pp_drag_pipe_2;
        
        // Fourth pipe takes values from third pipe
        s5_pp_drag_pipe_4 <= s5_pp_drag_pipe_3;
        
        // Fifth pipe takes values from fourth pipe
        s5_pp_drag_pipe_5 <= s5_pp_drag_pipe_4;
        
        s5_pipe <= s5;
        c5_pipe <= c5;
    end
end
  
    
endmodule 