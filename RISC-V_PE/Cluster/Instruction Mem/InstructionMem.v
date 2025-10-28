
module instruction_memory #(parameter NUM_PE = 4, parameter DEPTH = 256, parameter SENTINEL = 32'hFFFFFFFF)(
    input clk,
    input reset,
    input [NUM_PE-1:0] read_enable,
    input [NUM_PE*32-1:0] PC,
    output reg [NUM_PE*32-1:0] instruction,
    output reg last_instruction
);

    reg [31:0] memory_array [0:DEPTH-1];
    integer NUM_INSTRUCTIONS;
    integer i;
    reg [31:0] pc_i;
    reg done;

    initial begin
        $readmemh("instructions_test.hex", memory_array);
        NUM_INSTRUCTIONS = 0;
        done = 0;

        for (i = 0; i < DEPTH; i = i + 1) begin
            if (!done) begin
                if (memory_array[i] == SENTINEL) begin
                    done = 1;
                end else begin
                    NUM_INSTRUCTIONS = NUM_INSTRUCTIONS + 1;
                end
            end
        end

        $display("Loaded %0d instructions before sentinel", NUM_INSTRUCTIONS);
    end

    always @(posedge clk) begin
        if (reset) begin
            instruction <= 0;
            last_instruction <= 0;
        end else begin
            for (i = 0; i < NUM_PE; i = i + 1) begin
                pc_i = PC[i*32 +: 32];
                if (read_enable[i] && pc_i < NUM_INSTRUCTIONS && !last_instruction) begin
                    instruction[(NUM_PE - 1 - i)*32 +: 32] <= memory_array[pc_i];
                    $display("PE%0d: PC=%0d, Instruction=%h", i, pc_i, memory_array[pc_i]);
                    if (pc_i == NUM_INSTRUCTIONS - 1) begin
                        last_instruction <= 1;
                        $display("Last Instruction has been read");
                    end
                end else begin
                    instruction[(NUM_PE - 1 - i)*32 +: 32] <= 32'b0;
                end
            end
        end
    end

endmodule
