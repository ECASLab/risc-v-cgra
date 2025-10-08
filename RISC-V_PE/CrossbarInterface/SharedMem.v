module shared_memory (
    input clk,
    input [31:0] address,   // Address from the PE
    input [31:0] write_data, // Data to be written
    input mem_read,         // Read enable
    input mem_write,        // Write enable
    output reg [31:0] read_data // Data read from memory
);
    reg [31:0] memory [0:255]; // 256 words of 32-bit memory

    always @(posedge clk) begin
        if (mem_write) begin
            memory[address] <= write_data;
        end
        if (mem_read) begin
            read_data <= memory[address];
        end
    end
endmodule
