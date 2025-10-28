module global_memory #(parameter NUM_PE = 4, parameter DEPTH = 256)(
    input clk,
    input reset,
    input [NUM_PE*32-1:0] mem_address,
    input [NUM_PE*32-1:0] mem_write_data,
    input [NUM_PE-1:0] mem_write,
    input [NUM_PE-1:0] mem_read,

    output reg [NUM_PE*32-1:0] mem_read_data,
    output reg [NUM_PE-1:0] mem_ack
);

    // Memory array
    reg [31:0] memory_array [0:DEPTH-1];

    integer i;
    reg [31:0] addr_i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_read_data <= 0;
            mem_ack <= 0;
        end else begin
            mem_ack <= 0;
            for (i = 0; i < NUM_PE; i = i + 1) begin
                addr_i = mem_address[i*32 +: 32];

                // Write operation
                if (mem_write[i]) begin
                    memory_array[addr_i] <= mem_write_data[i*32 +: 32];
                end

                // Read operation
                if (mem_read[i]) begin
                    mem_read_data[i*32 +: 32] <= memory_array[addr_i];
                    mem_ack[i] <= 1'b1;
                end else begin
                    mem_read_data[i*32 +: 32] <= 32'b0;
                end
            end
        end
    end
endmodule
