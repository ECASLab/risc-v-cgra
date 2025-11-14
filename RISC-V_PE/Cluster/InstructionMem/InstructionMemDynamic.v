
module instruction_memory_dynamic #(parameter NUM_PE = 4, parameter DEPTH = 256, parameter SENTINEL = 32'hFFFFFFFF)(
    input clk,
    input reset,

    //Read Interface
    input [NUM_PE-1:0] read_enable,
    input [NUM_PE*32-1:0] PC,
    output reg [NUM_PE*32-1:0] instruction,
    output reg last_instruction,

    //Write Interface
    input write_enable,
    input [31:0] write_data,
    input [31:0] write_address
);

    reg [31:0] memory_array [0:DEPTH-1];
    integer NUM_INSTRUCTIONS;
    integer i;
    reg [31:0] pc_i;
    reg done;

    always @(posedge clk) begin
        if (reset) begin
            instruction <= 0;
            last_instruction <= 0;
            NUM_INSTRUCTIONS <= 0;
        end else begin
            // Handle dynamic write
            if (write_enable && write_address < DEPTH) begin
                memory_array[write_address] <= write_data;
                if (write_data != SENTINEL && write_address >= NUM_INSTRUCTIONS) begin
                    NUM_INSTRUCTIONS <= write_address + 1;
                end
                $display("Write: Addr=%0d, Data=%h", write_address, write_data);
            end

            // Handle instruction read
            //last_instruction <= 0;
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
