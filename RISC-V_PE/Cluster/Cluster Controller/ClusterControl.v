module cluster_instruction_controller #(parameter NUM_PE = 4)(
    input clk,
    input reset,

    // Instruction memory interface
    output reg [NUM_PE-1:0] read_enable,
    output reg [NUM_PE*32-1:0] PC,
    input [NUM_PE*32-1:0] instruction,
    input last_instruction,

    // Cluster interface
    output reg [NUM_PE*32-1:0] PCin,
    output reg [NUM_PE*32-1:0] instructions,
    input [NUM_PE*32-1:0] PCout,
    input [NUM_PE-1:0] execution_complete,

    // Global controller signal
    output reg done
);

    reg [31:0] pc_array [NUM_PE-1:0];
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < NUM_PE; i = i + 1) begin
                pc_array[i] <= 0;
            end
            done <= 0;
        end else begin
            // Update PC: branch or sequential
            for (i = 0; i < NUM_PE; i = i + 1) begin
                if (PCout[i*32 +: 32] != pc_array[i]) begin
                    pc_array[i] <= PCout[i*32 +: 32]; // Branch
                end else begin
                    pc_array[i] <= pc_array[i] + 1;   // Sequential
                end
            end

            // Drive PC and PCin
            for (i = 0; i < NUM_PE; i = i + 1) begin
                PC[i*32 +: 32]   <= pc_array[i];
                PCin[i*32 +: 32] <= pc_array[i];
            end

            // Drive instructions
            instructions <= instruction;

            // Enable all PEs to read
            read_enable <= {NUM_PE{1'b1}};

            // Detect end of program
            if (last_instruction && (&execution_complete)) begin
                done <= 1;
            end
        end
    end
endmodule
