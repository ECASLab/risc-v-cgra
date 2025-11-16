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
    output reg IREnableExt,
    input [NUM_PE*32-1:0] PCout,
    input [NUM_PE-1:0] execution_complete,

    // Global controller signal
    output reg done,

    //Instruction dispatcher
    input program_loaded
);

    reg [31:0] pc_array [NUM_PE-1:0];
    reg branch_detected;
    reg [31:0] branch_target;
    reg executing;
    reg done_pending;
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < NUM_PE; i = i + 1) begin
                pc_array[i] <= i; // Initial dispatch: 0,1,2,3
            end
            done <= 0;
            read_enable <= 0;
            instructions <= 0;
            branch_detected <= 0;
            branch_target <= 0;
            done_pending <= 0;
            PC <= 0;
            PCin <= 0;
            executing <= 0;
            IREnableExt <= 0;
        end else begin
            if (!executing && program_loaded) begin
                executing <= 1;
            end

            if (executing && execution_complete==0 && !done) begin

                // Drive PC and PCin to instruction memory and cluster
                for (i = 0; i < NUM_PE; i = i + 1) begin
                    PC[i*32 +: 32]   <= pc_array[i];
                    PCin[i*32 +: 32] <= pc_array[i];
                end

                read_enable <= {NUM_PE{1'b1}};
                instructions <= instruction;
                IREnableExt <= 1;

                if (last_instruction) begin
                    done_pending <= 1;
                    read_enable <= 0;
                end
            end else if (executing && !done) begin
                //Branch can only happen after first execution (PCout has been calculated)
                branch_detected <= 0;
                branch_target <= 0;
                // Compute next PC values
                for (i = 0; i < NUM_PE; i = i + 1) begin
                    if (!branch_detected && PCout[i*32 +: 32] != pc_array[i]) begin
                        // Branch detected
                        branch_target <= PCout[i*32 +: 32];
                        branch_detected <= 1;
                    end 
                end

                for (i = 0; i < NUM_PE; i = i + 1) begin
                    if (branch_detected) begin
                        pc_array[i] <= branch_target + i;
                    end else begin
                        pc_array[i] <= pc_array[i] + NUM_PE;
                    end
                end

                // Drive PC and PCin to instruction memory and cluster
                for (i = 0; i < NUM_PE; i = i + 1) begin
                    PC[i*32 +: 32]   <= pc_array[i];
                    PCin[i*32 +: 32] <= pc_array[i];
                end

                read_enable <= {NUM_PE{1'b1}};
                instructions <= instruction;
                IREnableExt <= 1;

                if (last_instruction) begin
                    done_pending <= 1;
                    read_enable <= 0;
                end

            end else begin
                read_enable <= 0;
            end

            if (execution_complete == 4'b1111 & done_pending == 1) begin
                done <= 1;
                read_enable <= 0;
            end

        end
    end
endmodule
