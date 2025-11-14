`include "InstructionDispatcher.v"
`timescale 1ns / 1ps

module tb_global_instruction_dispatcher;

    parameter NUM_CLUSTERS = 4;
    parameter INSTR_PER_CLUSTER = 8;

    reg clk;
    reg reset;
    wire [NUM_CLUSTERS-1:0] write_enable;
    wire [31:0] write_data;
    wire [31:0] write_address;
    wire [NUM_CLUSTERS-1:0] cluster_select;
    wire dispatch_done;

    global_instruction_dispatcher #(
        .NUM_CLUSTERS(NUM_CLUSTERS),
        .INSTR_PER_CLUSTER(INSTR_PER_CLUSTER)
    ) dut (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .write_data(write_data),
        .write_address(write_address),
        .cluster_select(cluster_select),
        .dispatch_done(dispatch_done)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Starting global instruction dispatcher testbench...");
        clk = 0;
        reset = 1;
        #10;

        reset = 0;

        // Monitor writes
        forever begin
            @(posedge clk);
            if (|write_enable) begin
                $display("Time: %0dns | Cluster: %0d | Addr: %0d | Data: %h",
                    $time,
                    cluster_select_to_id(cluster_select),
                    write_address,
                    write_data
                );
            end
            if (dispatch_done) begin
                $display("Instruction dispatch complete.");
                #10;
                $finish;
            end
        end
    end

    // Helper function to decode one-hot cluster_select
    function integer cluster_select_to_id;
        input [NUM_CLUSTERS-1:0] sel;
        integer j;
        begin
            cluster_select_to_id = -1;
            for (j = 0; j < NUM_CLUSTERS; j = j + 1) begin
                if (sel[j]) cluster_select_to_id = j;
            end
        end
    endfunction

endmodule
