module instruction_memory (
    input clk,
    input reset,
    input [3:0] read_enable,          // Read enable signals for 4 PEs
    input [31:0] PC,            // 32-bit Program counter for first instruction
    output reg [127:0] instruction,    // Flattened 4 × 32-bit instruction bus
    output reg    last_instruction
);
    parameter DEPTH = 16; //Array capacity parameter
    parameter NUM_INSTRUCTIONS = 5; //Todo set actual number of instructions in file

    // Memory array to store instructions
    reg [31:0] memory_array [0:DEPTH - 1]; // 256 instructions, 32 bits wide

    // Initialize the instruction memory (optional for simulation)
    initial begin
        $readmemh("instructions_test.hex", memory_array); // Load instructions from a file
    end

    integer i;

    // Fetch instructions for each PE
    always @(posedge clk) begin
        if (reset)
        begin
            instruction <= 128'b0;
            last_instruction <= 1'b0;
        end
        for (i = 0; i < 4; i = i + 1) begin
                if ((PC + i < NUM_INSTRUCTIONS) && read_enable[i])
                begin
                    $display("Instruction read: %h", memory_array[PC + i]);
                    instruction[i*32 +: 32] <= memory_array[PC + i];
                end
                else
                    instruction[i*32 +: 32] <= 32'b0;
        end

        if ( (PC == (NUM_INSTRUCTIONS - 1)) || ((PC + 1) == (NUM_INSTRUCTIONS - 1)) || ((PC + 2) == (NUM_INSTRUCTIONS - 1)) || ((PC + 3) == (NUM_INSTRUCTIONS - 1)) )
                last_instruction <= 1'b1;
        else
                last_instruction <= 1'b0;

        if (read_enable == 4'b0)
            instruction <= 128'b0; 
    end
endmodule
