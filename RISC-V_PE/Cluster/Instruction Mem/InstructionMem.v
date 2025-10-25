module instruction_memory #(parameter NUM_PE = 4) (
    input clk,
    input reset,
    input [NUM_PE-1:0] read_enable,
    input [NUM_PE*32-1:0] PC,
    output reg [NUM_PE*32-1:0] instruction,
    output reg last_instruction
);
    parameter DEPTH = 16;
    parameter NUM_INSTRUCTIONS = 5; //Modify to use the correct number of instructions

    reg [31:0] memory_array [0:DEPTH - 1];

    initial begin
        $readmemh("instructions_test.hex", memory_array);
    end

    integer i;
    reg [31:0] pc_i;

    always @(posedge clk) begin
        if (reset) begin
            instruction <= 0;
            last_instruction <= 0;
        end else begin
            last_instruction <= 0;
            for (i = 0; i < NUM_PE; i = i + 1) begin
                pc_i = PC[i*32 +: 32];
                if (read_enable[i] && pc_i < NUM_INSTRUCTIONS) begin
                    instruction[i*32 +: 32] <= memory_array[pc_i];
                    $display("PE%0d: PC=%0d, Instruction=%h", i, pc_i, memory_array[pc_i]);
                    if (pc_i == NUM_INSTRUCTIONS - 1)
                        last_instruction <= 1;
                end else begin
                    instruction[i*32 +: 32] <= 32'b0;
                end
            end
        end
    end
endmodule
