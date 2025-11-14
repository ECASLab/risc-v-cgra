module mux32_4 (
    input      [31:0] in_1,
    input      [31:0] in_2,
    input      [31:0] in_3,
    input      [31:0] in_4,
    input      [31:0] in_5,
    input      [31:0] in_6,
    input      [31:0] in_7,
    input      [31:0] in_8,
    input      [31:0] in_9,
    input      [31:0] in_10,
    input      [31:0] in_11,
    input      [31:0] in_12,
    input      [31:0] in_13,
    input      [31:0] in_14,
    input      [31:0] in_15,
    input      [31:0] in_16,
    input      [31:0] in_17,
    input      [31:0] in_18,
    input      [31:0] in_19,
    input      [31:0] in_20,
    input      [31:0] in_21,
    input      [31:0] in_22,
    input      [31:0] in_23,
    input      [31:0] in_24,
    input      [31:0] in_25,
    input      [31:0] in_26,
    input      [31:0] in_27,
    input      [31:0] in_28,
    input      [31:0] in_29,
    input      [31:0] in_30,
    input      [31:0] in_31,
    input      [31:0] in_32,

    input      [4:0]  sel0,
    input      [4:0]  sel1,
    input      [4:0]  sel2,
    input      [4:0]  sel3,
    input      [4:0]  sel4,
    input      [4:0]  sel5,
    input      [4:0]  sel6,
    input      [4:0]  sel7,

    input             read_en0,
    input             read_en1,
    input             read_en2,
    input             read_en3,
    input             reg_select0,
    input             reg_select1,
    input             reg_select2,
    input             reg_select3,

    output reg [31:0] data_out0,
    output reg [31:0] data_out1,
    output reg [31:0] data_out2,
    output reg [31:0] data_out3,
    output reg [31:0] data_out4,
    output reg [31:0] data_out5,
    output reg [31:0] data_out6,
    output reg [31:0] data_out7,

    output reg        regComplete0,
    output reg        regComplete1,
    output reg        regComplete2,
    output reg        regComplete3
);
    always @(*) begin
        regComplete0 = 0;
        regComplete1 = 0;
        regComplete2 = 0;
        regComplete3 = 0;

        if (read_en0) begin
            data_out0 = select(sel0);
            if (reg_select0) begin
                data_out1 = select(sel1);
            end
            regComplete0 = 1;
        end
        else begin
            data_out0 = 32'hXXXXXXXX;
            data_out1 = 32'hXXXXXXXX;
        end
        if (read_en1) begin
            data_out2 = select(sel2);
            if (reg_select1) begin
                data_out3 = select(sel3);
            end
            regComplete1 = 1;
        end
        else begin
            data_out2 = 32'hXXXXXXXX;
            data_out3 = 32'hXXXXXXXX;
        end
        if (read_en2) begin
            data_out4 = select(sel4);
            if (reg_select2) begin
                data_out5 = select(sel5);
            end
            regComplete2 = 1;
        end
        else begin
            data_out4 = 32'hXXXXXXXX;
            data_out5 = 32'hXXXXXXXX;
        end
        if (read_en3) begin
            data_out6 = select(sel6);
            if (reg_select3) begin
                data_out7 = select(sel7);
            end
            regComplete3 = 1;
        end
        else begin
            data_out6 = 32'hXXXXXXXX;
            data_out7 = 32'hXXXXXXXX;
        end
    end

    // Local function-style task to select register
    function [31:0] select;
        input [4:0] sel;
        begin
            case (sel)
                5'd0:  select = in_1;
                5'd1:  select = in_2;
                5'd2:  select = in_3;
                5'd3:  select = in_4;
                5'd4:  select = in_5;
                5'd5:  select = in_6;
                5'd6:  select = in_7;
                5'd7:  select = in_8;
                5'd8:  select = in_9;
                5'd9:  select = in_10;
                5'd10: select = in_11;
                5'd11: select = in_12;
                5'd12: select = in_13;
                5'd13: select = in_14;
                5'd14: select = in_15;
                5'd15: select = in_16;
                5'd16: select = in_17;
                5'd17: select = in_18;
                5'd18: select = in_19;
                5'd19: select = in_20;
                5'd20: select = in_21;
                5'd21: select = in_22;
                5'd22: select = in_23;
                5'd23: select = in_24;
                5'd24: select = in_25;
                5'd25: select = in_26;
                5'd26: select = in_27;
                5'd27: select = in_28;
                5'd28: select = in_29;
                5'd29: select = in_30;
                5'd30: select = in_31;
                5'd31: select = in_32;
                default: select = 32'b0;
            endcase
        end
    endfunction

endmodule