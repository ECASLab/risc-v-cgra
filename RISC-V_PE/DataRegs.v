`include "mux32_1.v"
`include "demux1_32.v"
`include "Datareg.v"


module register_system (
    input clk,                          // Clock signal
    input reset,                        // Reset signal
    input [4:0] selRD,                  // 5-bit select signal to choose the register to store
    input [4:0] selRS1, 
    input [4:0] selRS2,                 // 5-bit select signals to choose registers to read
    input       reg_select,             // Allows to select only 1 reg to read (0) or both (1) 
    input [31:0] data_in,               // 32-bit input data for write operations
    input rdwrite,                      // Write enable signal
    input read_en,                      // Read enable for output
    output wire [31:0] data_out1,       // 32-bit output data for read operations
    output wire [31:0] data_out2,       // 32-bit output data for read operations
    output wire        regComplete      // Indicates read operation is complete *dataReady
);

    // Internal wires and registers
    wire [31:0] demux_out [31:0];            // 32 outputs from the demux1_32
    wire [31:0] reg_out [31:0];              // 32 outputs from the registers
    reg         reg_enable[31:0];            // Enable for each register

    // Demultiplexer: Distribute `data_in` to the selected register
    demux1_32 demux (
        .data_in(rdwrite ? data_in : 32'b0),  // Pass `data_in` only if write_enable is high
        .sel(selRD),
        .out_1(demux_out[0]), .out_2(demux_out[1]), .out_3(demux_out[2]), .out_4(demux_out[3]),
        .out_5(demux_out[4]), .out_6(demux_out[5]), .out_7(demux_out[6]), .out_8(demux_out[7]),
        .out_9(demux_out[8]), .out_10(demux_out[9]), .out_11(demux_out[10]), .out_12(demux_out[11]),
        .out_13(demux_out[12]), .out_14(demux_out[13]), .out_15(demux_out[14]), .out_16(demux_out[15]),
        .out_17(demux_out[16]), .out_18(demux_out[17]), .out_19(demux_out[18]), .out_20(demux_out[19]),
        .out_21(demux_out[20]), .out_22(demux_out[21]), .out_23(demux_out[22]), .out_24(demux_out[23]),
        .out_25(demux_out[24]), .out_26(demux_out[25]), .out_27(demux_out[26]), .out_28(demux_out[27]),
        .out_29(demux_out[28]), .out_30(demux_out[29]), .out_31(demux_out[30]), .out_32(demux_out[31])
    );

    // Instantiate 32 registers
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : reg_block
            DataRegister reg_inst (
                .clock(clk),
                .reset(reset ? 1'b1:1'b0),
                .r_enable(reg_enable[i]),
                .data_in(demux_out[i]),      // Data from the demux
                .data_out(reg_out[i])       // Output of the register
            );
        end
    endgenerate

    // Multiplexer: Select the output of the desired register
    mux32_1 mux (
        .in_1(reg_out[0]), .in_2(reg_out[1]), .in_3(reg_out[2]), .in_4(reg_out[3]),
        .in_5(reg_out[4]), .in_6(reg_out[5]), .in_7(reg_out[6]), .in_8(reg_out[7]),
        .in_9(reg_out[8]), .in_10(reg_out[9]), .in_11(reg_out[10]), .in_12(reg_out[11]),
        .in_13(reg_out[12]), .in_14(reg_out[13]), .in_15(reg_out[14]), .in_16(reg_out[15]),
        .in_17(reg_out[16]), .in_18(reg_out[17]), .in_19(reg_out[18]), .in_20(reg_out[19]),
        .in_21(reg_out[20]), .in_22(reg_out[21]), .in_23(reg_out[22]), .in_24(reg_out[23]),
        .in_25(reg_out[24]), .in_26(reg_out[25]), .in_27(reg_out[26]), .in_28(reg_out[27]),
        .in_29(reg_out[28]), .in_30(reg_out[29]), .in_31(reg_out[30]), .in_32(reg_out[31]),
        .selrs1(selRS1), .selrs2(selRS2), .reg_select(reg_select),
        .data_out1(data_out1), .data_out2(data_out2), .read_en(read_en), .regComplete(regComplete)
    );

    always @(posedge clk ) begin
        if (rdwrite == 1)
        begin
            $display("Data will be written at register: %b", selRD);
            case (selRD)    
            5'b00000: reg_enable[0] = 1;
            5'b00001: reg_enable[1] = 1; 
            5'b00010: reg_enable[2] = 1;
            5'b00011: reg_enable[3] = 1; 
            5'b00100: reg_enable[4] = 1;
            5'b00101: reg_enable[5] = 1;
            5'b00110: reg_enable[6] = 1;
            5'b00111: reg_enable[7] = 1;
            5'b01000: reg_enable[8] = 1;
            5'b01001: reg_enable[9] = 1;
            5'b01010: reg_enable[10] = 1;
            5'b01011: reg_enable[11] = 1; 
            5'b01100: reg_enable[12] = 1;
            5'b01101: reg_enable[13] = 1; 
            5'b01110: reg_enable[14] = 1; 
            5'b01111: reg_enable[15] = 1;
            5'b10000: reg_enable[16] = 1;
            5'b10001: reg_enable[17] = 1;
            5'b10010: reg_enable[18] = 1;
            5'b10011: reg_enable[19] = 1;
            5'b10100: reg_enable[20] = 1;
            5'b10101: reg_enable[21] = 1;
            5'b10110: reg_enable[22] = 1;
            5'b10111: reg_enable[23] = 1;
            5'b11000: reg_enable[24] = 1;
            5'b11001: reg_enable[25] = 1;
            5'b11010: reg_enable[26] = 1;
            5'b11011: reg_enable[27] = 1;
            5'b11100: reg_enable[28] = 1;
            5'b11101: reg_enable[29] = 1;
            5'b11110: reg_enable[30] = 1;
            5'b11111: reg_enable[31] = 1;
        endcase
        end
        else
        begin
            reg_enable[0] = 0;
            reg_enable[1] = 0; 
            reg_enable[2] = 0;
            reg_enable[3] = 0; 
            reg_enable[4] = 0;
            reg_enable[5] = 0;
            reg_enable[6] = 0;
            reg_enable[7] = 0;
            reg_enable[8] = 0;
            reg_enable[9] = 0;
            reg_enable[10] = 0;
            reg_enable[11] = 0; 
            reg_enable[12] = 0;
            reg_enable[13] = 0; 
            reg_enable[14] = 0; 
            reg_enable[15] = 0;
            reg_enable[16] = 0;
            reg_enable[17] = 0;
            reg_enable[18] = 0;
            reg_enable[19] = 0;
            reg_enable[20] = 0;
            reg_enable[21] = 0;
            reg_enable[22] = 0;
            reg_enable[23] = 0;
            reg_enable[24] = 0;
            reg_enable[25] = 0;
            reg_enable[26] = 0;
            reg_enable[27] = 0;
            reg_enable[28] = 0;
            reg_enable[29] = 0;
            reg_enable[30] = 0;
            reg_enable[31] = 0;
        end
    end
endmodule
