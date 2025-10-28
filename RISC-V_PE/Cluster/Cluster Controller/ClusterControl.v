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
    reg branch_detected;
    reg [31:0] branch_target;
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
            PC <= 0;
            PCin <= 0;
        end else begin
            branch_detected <= 0;
            branch_target <= 0;
            if (&execution_complete && !done) begin
                // Compute next PC values
                for (i = 0; i < NUM_PE; i = i + 1) begin
                    $display("PC out is %h whle pc_array is %h", PCout[i*32 +: 32], pc_array[i]);
                    if (!branch_detected && PCout[i*32 +: 32] != pc_array[i]) begin
                        // Branch detected
                        branch_target = PCout[i*32 +: 32];
                        $display("Branch detected for PE%0d: jumping to %0d", i, branch_target);
                        branch_detected = 1;
                    end 
                end

                for (i = 0; i < NUM_PE; i = i + 1) begin
                    if (branch_detected) begin
                        pc_array[i] <= branch_target + i;
                        $display("Branch dispatch for PE%0d: PC %0d", i, branch_target + i);
                    end else begin
                        pc_array[i] <= pc_array[i] + NUM_PE;
                        $display("Sequential increment for PE%0d: next PC %0d", i, pc_array[i] + NUM_PE);
                    end
                end

                // Drive PC and PCin to instruction memory and cluster
                for (i = 0; i < NUM_PE; i = i + 1) begin
                    PC[i*32 +: 32]   <= pc_array[i];
                    PCin[i*32 +: 32] <= pc_array[i];
                end

                read_enable <= {NUM_PE{1'b1}};
                instructions <= instruction;

                if (last_instruction) begin
                    done = 1;
                    $display("All instructions have been read");
                end
            end else begin
                read_enable <= 0;
            end
        end
    end
endmodule
