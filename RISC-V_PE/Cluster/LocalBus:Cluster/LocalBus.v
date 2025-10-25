`include "../Cluster Controller/ClusterControl.v"
`include "../Instruction Mem/InstructionMem.v"
`include "../LocalBus:Cluster/Cluster4.v"


module local_bus_control #(parameter NUM_PE = 4)(
    input clk,                     // Clock signal
    input reset,                   // Reset signal
    // Outputs for global memory (cluster outputs for now)
    input [NUM_PE-1:0] mem_ack_global,  // Coming from global memory
    input [NUM_PE*32-1:0] mem_data_global, // Data being read from global mem

    output [NUM_PE*32-1:0] mem_address_global, // Addresses to read from global mem
    output [NUM_PE*32-1:0] result_out,         // Result from PE output *Might be an internal signal
    output [NUM_PE*32-1:0] mem_write_data_global, // Data output from PEs to write to memory *Might use the result_out
    output [NUM_PE-1:0] mem_write_global,   // To send write signal to global mem
    output [NUM_PE-1:0] mem_read_global,    // To send read signal to global mem
    output [NUM_PE-1:0] branch_exec,
    output done
);
    wire [NUM_PE-1:0] read_enable;
    wire [NUM_PE*32-1:0] PC; //To instruction memory
    wire [NUM_PE*32-1:0] instruction; //To instruction memory
    wire last_instruction; //From instruction memory
    wire [NUM_PE*32-1:0] PCin; //To PE cluster
    wire [NUM_PE*32-1:0] instructions;  //To PE cluster
    wire [NUM_PE*32-1:0] PCout; //From PE cluster
    wire [NUM_PE-1:0] execution_complete; //From PE cluster


    // Controller
    cluster_instruction_controller #(NUM_PE) controller (
        .clk(clk),
        .reset(reset),
        .read_enable(read_enable),
        .PC(PC),
        .instruction(instruction),
        .last_instruction(last_instruction),
        .PCin(PCin),
        .instructions(instructions),
        .PCout(PCout),
        .execution_complete(execution_complete),
        .done(done)
    );

    // Instruction Memory 
    instruction_memory #(NUM_PE) instr_mem (
        .clk(clk),
        .reset(reset),
        .read_enable(read_enable),
        .PC(PC),
        .instruction(instruction),
        .last_instruction(last_instruction)
    );

    //Cluster PE_system
    local_bus_top #(NUM_PE) cluster (
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

endmodule
