// Demux 1_32 Testbench

`include "demux1_32.v"

`timescale 1ns / 1ps

module tb_demux1_32;

    // Testbench signals
    reg [31:0] data_in;              // Input data
    reg [4:0] sel;                   // 5-bit selection signal
    wire [31:0] out_1, out_2, out_3, out_4, out_5, out_6, out_7, out_8, 
                out_9, out_10, out_11, out_12, out_13, out_14, out_15, out_16,
                out_17, out_18, out_19, out_20, out_21, out_22, out_23, out_24,
                out_25, out_26, out_27, out_28, out_29, out_30, out_31, out_32;

    // Instantiate the demux1_32 module
    demux1_32 uut (
        .data_in(data_in),
        .sel(sel),
        .out_1(out_1), .out_2(out_2), .out_3(out_3), .out_4(out_4), 
        .out_5(out_5), .out_6(out_6), .out_7(out_7), .out_8(out_8), 
        .out_9(out_9), .out_10(out_10), .out_11(out_11), .out_12(out_12), 
        .out_13(out_13), .out_14(out_14), .out_15(out_15), .out_16(out_16),
        .out_17(out_17), .out_18(out_18), .out_19(out_19), .out_20(out_20), 
        .out_21(out_21), .out_22(out_22), .out_23(out_23), .out_24(out_24),
        .out_25(out_25), .out_26(out_26), .out_27(out_27), .out_28(out_28),
        .out_29(out_29), .out_30(out_30), .out_31(out_31), .out_32(out_32)
    );

    // Initialize and run the simulation
    initial begin
        // Dump waveforms for debugging
        $dumpfile("tb_demux1_32.vcd");
        $dumpvars(0, tb_demux1_32);

         $monitor("Time: %0dns | out_1: %h | out_2: %h | out_3: %h | out_4: %h | out_5: %h | out_6: %h | out_7: %h | out_8: %h | out_9: %h | out_10: %h | out_11: %h | out_12: %h | out_13: %h", 
                 $time, out_1, out_2, out_3, out_4, out_5, out_6, out_7, out_8, out_9, out_10, out_11, out_12, out_13);


        // Test all selection lines
        data_in = 32'hA5A5A5A5; // Example data pattern
        sel = 0; // Initialize selection

        // Iterate through all possible sel values
        repeat (32) begin
            #10; // Wait for 10 time units
            data_in = data_in + 1;
            $display("SEL=%d: out_1=%h, out_2=%h, out_3=%h, out_4=%h, out_5=%h, out_6=%h, out_7=%h, out_8=%h, out_9=%h, out_10=%h, out_11=%h, out_12=%h, out_13=%h, out_14=%h, out_15=%h, out_16=%h, out_17=%h, out_18=%h, out_19=%h, out_20=%h, out_21=%h, out_22=%h, out_23=%h, out_24=%h, out_25=%h, out_26=%h, out_27=%h, out_28=%h, out_29=%h, out_30=%h, out_31=%h, out_32=%h", 
                     sel, out_1, out_2, out_3, out_4, out_5, out_6, out_7, out_8, out_9, out_10, out_11, out_12, out_13, out_14, out_15, out_16, out_17, out_18, out_19, out_20, out_21, out_22, out_23, out_24, out_25, out_26, out_27, out_28, out_29, out_30, out_31, out_32);
            sel = sel + 1; // Increment selection
            $display("##########################################################################");
        end

        $finish; // End simulation
    end

endmodule