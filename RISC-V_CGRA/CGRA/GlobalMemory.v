module global_memory #(parameter NUM_PE = 4)(
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
    reg [31:0] memory_array [0:1024-1];

    integer i;
    reg [NUM_PE*32-1:0] addr_i;
    reg [NUM_PE-1:0] read_pending;
    reg [NUM_PE-1:0] write_pending;

    initial begin
        $readmemh("mem_init.hex", memory_array);
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_read_data <= 0;
            mem_ack <= 0;
            read_pending <= 0;
            write_pending <= 0;
        end else begin
            mem_ack <= 0;
            for (i = 0; i < NUM_PE; i = i + 1) begin
                if (mem_address[i*32 +: 32] != 0)
                begin
                    addr_i[i*32 +: 32] <= mem_address[i*32 +: 32];
                end
            end

            for (i = 0; i < NUM_PE; i = i + 1) begin
                // Write operation
                if (mem_write[i]) begin
                    write_pending[i] <= 1;
                end

                if (write_pending[i]) begin
                    memory_array[addr_i[i*32 +: 32]] <= mem_write_data[i*32 +: 32];
                    write_pending[i] <= 0;
                end

                // Read operation
                if (mem_read[i]) begin
                    read_pending[i] <= 1;
                end else begin
                    mem_read_data[i*32 +: 32] <= 32'b0;
                end

                if (read_pending[i])
                begin
                    mem_read_data[i*32 +: 32] <= memory_array[addr_i[i*32 +: 32]];
                    mem_ack[i] <= 1'b1;
                    read_pending[i] <= 0;
                end
            end
        end
    end
endmodule
