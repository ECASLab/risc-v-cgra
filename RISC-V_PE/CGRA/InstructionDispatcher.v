module global_instruction_dispatcher #(
    parameter NUM_CLUSTERS = 4,
    parameter INSTR_PER_CLUSTER = 16
)(
    input clk,
    input reset,
    output reg [NUM_CLUSTERS-1:0] write_enable,
    output reg [31:0] write_data,
    output reg [31:0] write_address,
    output reg [NUM_CLUSTERS-1:0] cluster_select,
    output reg [NUM_CLUSTERS-1:0] program_loaded,
    output reg dispatch_done
);

    reg [31:0] global_instruction_memory [0:NUM_CLUSTERS*INSTR_PER_CLUSTER-1];
    integer cluster_id, instr_id;

    initial begin
        $readmemh("global_program.hex", global_instruction_memory);
    end

    parameter IDLE     = 2'b00;
    parameter DISPATCH = 2'b01;
    parameter DONE     = 2'b10;

    reg [1:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cluster_id <= 0;
            instr_id <= 0;
            state <= IDLE;
            dispatch_done <= 0;
            write_enable <= 0;
            cluster_select <= 0;
            program_loaded <= 0;
        end else begin
            case (state)
                IDLE: begin
                    state <= DISPATCH;
                end

                DISPATCH: begin
                    write_data <= global_instruction_memory[cluster_id*INSTR_PER_CLUSTER + instr_id];
                    write_address <= instr_id;
                    write_enable <= 1 << cluster_id;
                    cluster_select <= 1 << cluster_id;

                    instr_id <= instr_id + 1;

                    if (instr_id == INSTR_PER_CLUSTER - 1) begin
                        instr_id <= 0;
                        cluster_id <= cluster_id + 1;
                        if (cluster_id == NUM_CLUSTERS - 1) begin
                            state <= DONE;
                        end
                    end
                end

                DONE: begin
                    write_enable <= 0;
                    cluster_select <= 0;
                    dispatch_done <= 1;
                    program_loaded <= 4'b1111;
                end
            endcase
        end
    end
endmodule
