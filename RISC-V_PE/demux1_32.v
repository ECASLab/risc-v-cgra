module demux1_32 (
    input      [31:0] data_in,
    output reg [31:0] out_1,
    output reg [31:0] out_2,
    output reg [31:0] out_3,
    output reg [31:0] out_4,
    output reg [31:0] out_5,
    output reg [31:0] out_6,
    output reg [31:0] out_7,
    output reg [31:0] out_8,
    output reg [31:0] out_9,
    output reg [31:0] out_10,
    output reg [31:0] out_11,
    output reg [31:0] out_12,
    output reg [31:0] out_13,
    output reg [31:0] out_14,
    output reg [31:0] out_15,
    output reg [31:0] out_16,
    output reg [31:0] out_17,
    output reg [31:0] out_18,
    output reg [31:0] out_19,
    output reg [31:0] out_20,
    output reg [31:0] out_21,
    output reg [31:0] out_22,
    output reg [31:0] out_23,
    output reg [31:0] out_24,
    output reg [31:0] out_25,
    output reg [31:0] out_26,
    output reg [31:0] out_27,
    output reg [31:0] out_28,
    output reg [31:0] out_29,
    output reg [31:0] out_30,
    output reg [31:0] out_31,
    output reg [31:0] out_32,
    input      [4:0]  sel
);
    always @(*) begin
        case(sel)
            5'b00000: out_1 = data_in; 
            5'b00001: out_2 = data_in; 
            5'b00010: out_3 = data_in; 
            5'b00011: 
            begin
                out_4 = data_in; 
                $display("Data out for Reg 3 is :" + out_4);
            end
            5'b00100: 
            begin
                out_5 = data_in; 
                $display("Data out for Reg 4 is :" + out_4);
            end
            5'b00101: 
            begin 
                out_6 = data_in; 
                $display("Data out for Reg 3 is :" + out_4);
            end
            5'b00110: out_7 = data_in; 
            5'b00111: out_8 = data_in; 
            5'b01000: out_9 = data_in; 
            5'b01001: out_10 = data_in; 
            5'b01010: out_11 = data_in; 
            5'b01011: out_12 = data_in; 
            5'b01100: out_13 = data_in; 
            5'b01101: out_14 = data_in; 
            5'b01110: out_15 = data_in; 
            5'b01111: out_16 = data_in; 
            5'b10000: out_17 = data_in; 
            5'b10001: out_18 = data_in; 
            5'b10010: out_19 = data_in; 
            5'b10011: out_20 = data_in; 
            5'b10100: out_21 = data_in; 
            5'b10101: out_22 = data_in; 
            5'b10110: out_23 = data_in; 
            5'b10111: out_24 = data_in; 
            5'b11000: out_25 = data_in; 
            5'b11001: out_26 = data_in; 
            5'b11010: out_27 = data_in; 
            5'b11011: out_28 = data_in; 
            5'b11100: out_29 = data_in; 
            5'b11101: out_30 = data_in; 
            5'b11110: out_31 = data_in; 
            5'b11111: out_32 = data_in; 
        endcase
    end

endmodule