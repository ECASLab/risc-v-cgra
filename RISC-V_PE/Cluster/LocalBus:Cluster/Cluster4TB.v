`timescale 1ns / 1ps
`include "Cluster4.v"

module local_bus_top_tb;

    // Parameters
    parameter NUM_PE = 4;
    parameter CLK_PERIOD = 10;
    
    // Testbench signals
    reg clk;
    reg reset;
    reg [NUM_PE*32-1:0] PCin;
    reg [NUM_PE*32-1:0] instructions;
    reg [NUM_PE-1:0] mem_ack_global;
    reg [NUM_PE*32-1:0] mem_data_global;
    
    wire [NUM_PE*32-1:0] mem_address_global;
    wire [NUM_PE*32-1:0] result_out;
    wire [NUM_PE*32-1:0] mem_write_data_global;
    wire [NUM_PE*32-1:0] PCout;
    wire [NUM_PE-1:0] mem_write_global;
    wire [NUM_PE-1:0] mem_read_global;
    wire [NUM_PE-1:0] execution_complete;
    wire [NUM_PE-1:0] branch_exec;
    
    // Monitoring variables
    integer cycle_count;
    integer parallel_access_count;
    integer total_memory_accesses;
    
    // DUT instantiation
    local_bus_top #(.NUM_PE(NUM_PE)) dut (
        .clk(clk),
        .reset(reset),
        .PCin(PCin),
        .instructions(instructions),
        .mem_ack_global(mem_ack_global),
        .mem_data_global(mem_data_global),
        .mem_address_global(mem_address_global),
        .result_out(result_out),
        .mem_write_data_global(mem_write_data_global),
        .PCout(PCout),
        .mem_write_global(mem_write_global),
        .mem_read_global(mem_read_global),
        .execution_complete(execution_complete),
        .branch_exec(branch_exec)
    );
    integer active_count;
    integer i;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Helper function to decode instruction type (basic RISC-V)
    function [79:0] decode_instruction;
        input [31:0] instr;
        reg [6:0] opcode;
        begin
            opcode = instr[6:0];
            case(opcode)
                7'b0110011: decode_instruction = "R-TYPE    ";
                7'b0010011: decode_instruction = "I-TYPE    ";
                7'b0000011: decode_instruction = "LOAD      ";
                7'b0100011: decode_instruction = "STORE     ";
                7'b1100011: decode_instruction = "BRANCH    ";
                7'b1101111: decode_instruction = "JAL       ";
                7'b1100111: decode_instruction = "JALR      ";
                7'b0110111: decode_instruction = "LUI       ";
                7'b0010111: decode_instruction = "AUIPC     ";
                default:    decode_instruction = "UNKNOWN   ";
            endcase
        end
    endfunction
    
    // Monitor instruction loading each cycle
    always @(posedge clk) begin
        if (!reset) begin
            $display("\n========== CYCLE %0d (Time: %0t ns) ==========", cycle_count, $time);
            
            // Display instructions for each PE
            $display("\n--- Instructions Loaded ---");
            for (integer i = 0; i < NUM_PE; i = i + 1) begin
                $display("PE[%0d]: PC=0x%08h | Instr=0x%08h | Type: %s", 
                    i, 
                    PCin[i*32 +: 32], 
                    instructions[i*32 +: 32],
                    decode_instruction(instructions[i*32 +: 32]));
            end
            
            // Display bus arbitration status
            $display("\n--- Bus Arbitration ---");
            $display("Bus Requests: %b", dut.bus_request);
            $display("Grants:       %b", dut.grant);
            $display("Working:      %b", dut.working);
            
            // Track memory access patterns
            $display("\n--- Memory Access Status ---");
            $display("Global Mem Read:  %b", mem_read_global);
            $display("Global Mem Write: %b", mem_write_global);
            $display("Mem Ack Global:   %b", mem_ack_global);
            $display("Local Data Ready: %b", dut.dataReady);
            
            // Check for parallel memory access
            if ((mem_read_global | mem_write_global) != 0) begin
                active_count = 0;
                $display("\nActive Memory Operations:");
                for (i = 0; i < NUM_PE; i = i + 1) begin
                    if (mem_read_global[i] || mem_write_global[i]) begin
                        active_count = active_count + 1;
                        $display("  PE[%0d]: %s | Address: 0x%08h", 
                            i,
                            mem_read_global[i] ? "READ " : "WRITE",
                            mem_address_global[i*32 +: 32]);
                        if (mem_write_global[i]) begin
                            $display("         Write Data: 0x%08h", mem_write_data_global[i*32 +: 32]);
                        end
                    end
                end
                
                total_memory_accesses = total_memory_accesses + active_count;
                
                if (active_count > 1) begin
                    $display("\n*** PARALLEL ACCESS DETECTED: %0d PEs accessing memory simultaneously! ***", active_count);
                    parallel_access_count = parallel_access_count + 1;
                end else begin
                    $display("\n(Sequential access - only 1 PE accessing memory)");
                end
            end else begin
                $display("(No memory access this cycle)");
            end
            
            // Display local memory operations
            $display("\n--- Local Memory Access ---");
            $display("Read Enable:  %b", dut.read_en);
            $display("Write Enable: %b", dut.rd_write);
            $display("Reg Select:   %b", dut.reg_select);
            
            // Display execution status
            $display("\n--- Execution Status ---");
            $display("Execution Complete: %b", execution_complete);
            $display("Branch Executed:    %b", branch_exec);
            
            // Display results
            $display("\n--- PE Outputs ---");
            for (i = 0; i < NUM_PE; i = i + 1) begin
                $display("PE[%0d]: Result=0x%08h | PC_out=0x%08h", 
                    i, 
                    result_out[i*32 +: 32],
                    PCout[i*32 +: 32]);
            end
            
            $display("=" , {"=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "=", "="});
            
            cycle_count = cycle_count + 1;
        end
    end
    
    // Test stimulus
    initial begin
        // Initialize signals
        reset = 1;
        PCin = 0;
        instructions = 0;
        mem_ack_global = 0;
        mem_data_global = 0;
        cycle_count = 0;
        parallel_access_count = 0;
        total_memory_accesses = 0;
        
        $display("\n\n");
        $display("====================================================================");
        $display("         LOCAL BUS TOP TESTBENCH - PARALLEL ACCESS MONITOR         ");
        $display("====================================================================");
        $display("Number of PEs: %0d", NUM_PE);
        $display("Clock Period: %0d ns", CLK_PERIOD);
        $display("====================================================================\n");
        
        // Reset sequence
        #(CLK_PERIOD*2);
        reset = 0;
        #(CLK_PERIOD);
        
        // Test Case 1: All PEs execute LOAD instructions
        $display("\n\n");
        $display("====================================================================");
        $display("           TEST CASE 1: All PEs Execute LOAD Instructions          ");
        $display("           (Testing for Parallel Memory Read Access)               ");
        $display("====================================================================");
        
        // All PEs execute LOAD instructions
        PCin[31:0]    = 32'h00001000;
        PCin[63:32]   = 32'h00001004;
        PCin[95:64]   = 32'h00001008;
        PCin[127:96]  = 32'h0000100C;
        
        // LOAD instructions (I-type: lw rd, offset(rs1))
        instructions[31:0]   = 32'h00052283; // lw x5, 0(x10) - PE0
        instructions[63:32]  = 32'h00462303; // lw x6, 4(x12) - PE1
        instructions[95:64]  = 32'h00872383; // lw x7, 8(x14) - PE2
        instructions[127:96] = 32'h00C82403; // lw x8, 12(x16) - PE3
        
        repeat(5) @(posedge clk);
        
        // Simulate memory acknowledgments
        $display("\n>>> Providing memory acknowledgments for loads...");
        mem_ack_global = 4'b1111;
        mem_data_global = {32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, 32'hABCDEF00};
        @(posedge clk);
        mem_ack_global = 0;
        
        repeat(3) @(posedge clk);
        
        // Test Case 2: All PEs execute STORE instructions
        $display("\n\n");
        $display("====================================================================");
        $display("          TEST CASE 2: All PEs Execute STORE Instructions          ");
        $display("           (Testing for Parallel Memory Write Access)              ");
        $display("====================================================================");
        
        PCin = PCin + {32'd4, 32'd4, 32'd4, 32'd4};
        
        // STORE instructions (S-type: sw rs2, offset(rs1))
        instructions[31:0]   = 32'h00552023; // sw x5, 0(x10) - PE0
        instructions[63:32]  = 32'h00662223; // sw x6, 4(x12) - PE1
        instructions[95:64]  = 32'h00772423; // sw x7, 8(x14) - PE2
        instructions[127:96] = 32'h00882623; // sw x8, 12(x16) - PE3
        
        repeat(5) @(posedge clk);
        
        // Test Case 3: Mixed operations
        $display("\n\n");
        $display("====================================================================");
        $display("              TEST CASE 3: Mixed PE Operations                     ");
        $display("     (R-type, I-type, LOAD, STORE - Testing Access Patterns)      ");
        $display("====================================================================");
        
        PCin = PCin + {32'd4, 32'd4, 32'd4, 32'd4};
        
        instructions[31:0]   = 32'h00A50533; // add x10, x10, x10 - R-type (no mem access)
        instructions[63:32]  = 32'h00462303; // lw x6, 4(x12) - LOAD (mem read)
        instructions[95:64]  = 32'h00772423; // sw x7, 8(x14) - STORE (mem write)
        instructions[127:96] = 32'h01460613; // addi x12, x12, 20 - I-type (no mem access)
        
        repeat(5) @(posedge clk);
        
        // Provide memory ack for PE1's load
        $display("\n>>> Providing memory acknowledgment for PE1's load...");
        mem_ack_global = 4'b0010;
        mem_data_global[63:32] = 32'h99998888;
        @(posedge clk);
        mem_ack_global = 0;
        
        repeat(3) @(posedge clk);
        
        // Test Case 4: Sequential loads (one at a time)
        $display("\n\n");
        $display("====================================================================");
        $display("        TEST CASE 4: Sequential LOAD Instructions                  ");
        $display("        (One PE at a time - Should show NO parallel access)        ");
        $display("====================================================================");
        
        // PE0 loads
        PCin[31:0] = 32'h00002000;
        instructions[31:0] = 32'h00052283; // lw x5, 0(x10)
        instructions[63:32] = 32'h00000013; // nop
        instructions[95:64] = 32'h00000013; // nop
        instructions[127:96] = 32'h00000013; // nop
        
        repeat(3) @(posedge clk);
        
        // PE1 loads
        PCin[63:32] = 32'h00002004;
        instructions[31:0] = 32'h00000013; // nop
        instructions[63:32] = 32'h00462303; // lw x6, 4(x12)
        instructions[95:64] = 32'h00000013; // nop
        instructions[127:96] = 32'h00000013; // nop
        
        repeat(3) @(posedge clk);
        
        // Summary statistics
        $display("\n\n");
        $display("====================================================================");
        $display("                      SIMULATION SUMMARY                           ");
        $display("====================================================================");
        $display("Total Cycles Simulated:         %0d", cycle_count);
        $display("Total Memory Accesses:          %0d", total_memory_accesses);
        $display("Cycles with Parallel Access:    %0d", parallel_access_count);
        $display("Cycles with Sequential Access:  %0d", cycle_count - parallel_access_count);
        if (cycle_count > 0) begin
            $display("Parallel Access Rate:           %.1f%%", 
                (parallel_access_count * 100.0) / cycle_count);
        end
        $display("====================================================================");
        
        $display("\nNOTE: Check for '*** PARALLEL ACCESS DETECTED ***' messages above");
        $display("to identify which cycles had multiple PEs accessing memory.\n");
        
        #(CLK_PERIOD*5);
        $finish;
    end

    
    // Waveform dump
    //initial begin
    //    $dumpfilb   $dumpvars(0, local_bus_top_tb);
    //end

endmodule