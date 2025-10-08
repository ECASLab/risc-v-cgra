module demux4_32 (
    input  [31:0] data_in0,
    input  [4:0]  sel0,
    input  [31:0] data_in1,
    input  [4:0]  sel1,
    input  [31:0] data_in2,
    input  [4:0]  sel2,
    input  [31:0] data_in3,
    input  [4:0]  sel3,
    output reg [31:0] out0,
    output reg [31:0] out1,
    output reg [31:0] out2,
    output reg [31:0] out3,
    output reg [31:0] out4,
    output reg [31:0] out5,
    output reg [31:0] out6,
    output reg [31:0] out7,
    output reg [31:0] out8,
    output reg [31:0] out9,
    output reg [31:0] out10,
    output reg [31:0] out11,
    output reg [31:0] out12,
    output reg [31:0] out13,
    output reg [31:0] out14,
    output reg [31:0] out15,
    output reg [31:0] out16,
    output reg [31:0] out17,
    output reg [31:0] out18,
    output reg [31:0] out19,
    output reg [31:0] out20,
    output reg [31:0] out21,
    output reg [31:0] out22,
    output reg [31:0] out23,
    output reg [31:0] out24,
    output reg [31:0] out25,
    output reg [31:0] out26,
    output reg [31:0] out27,
    output reg [31:0] out28,
    output reg [31:0] out29,
    output reg [31:0] out30,
    output reg [31:0] out31
);

    reg [31:0] temp_out [0:31];
    integer i;

    always @(*) begin

        temp_out[sel0] = data_in0;
        temp_out[sel1] = data_in1;
        temp_out[sel2] = data_in2;
        temp_out[sel3] = data_in3;

        // Assign to individual outputs
        out0  = temp_out[0];
        out1  = temp_out[1];
        out2  = temp_out[2];
        out3  = temp_out[3];
        out4  = temp_out[4];
        out5  = temp_out[5];
        out6  = temp_out[6];
        out7  = temp_out[7];
        out8  = temp_out[8];
        out9  = temp_out[9];
        out10 = temp_out[10];
        out11 = temp_out[11];
        out12 = temp_out[12];
        out13 = temp_out[13];
        out14 = temp_out[14];
        out15 = temp_out[15];
        out16 = temp_out[16];
        out17 = temp_out[17];
        out18 = temp_out[18];
        out19 = temp_out[19];
        out20 = temp_out[20];
        out21 = temp_out[21];
        out22 = temp_out[22];
        out23 = temp_out[23];
        out24 = temp_out[24];
        out25 = temp_out[25];
        out26 = temp_out[26];
        out27 = temp_out[27];
        out28 = temp_out[28];
        out29 = temp_out[29];
        out30 = temp_out[30];
        out31 = temp_out[31];
    end

endmodule
