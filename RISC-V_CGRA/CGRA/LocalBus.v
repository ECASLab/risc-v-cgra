module local_bus_control #(parameter NUM_PE = 4)(
    input clk,                     // Clock signal
    input reset,                   // Reset signal
    // Outputs for global memory (cluster outputs for now)
    input [NUM_PE-1:0] mem_ack_global,  // Coming from global memory
    input [NUM_PE*32-1:0] mem_data_global, // Data being read from global mem
    input program_loaded, //From instruction dispatcher

    input write_enable,
    input [31:0] write_data,
    input [31:0] write_address,
    input cluster_select,
    input [1:0] Clusterid,

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
    wire IREnableExt;


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
        .IREnableExt(IREnableExt),
        .execution_complete(execution_complete),
        .done(done),
        .program_loaded(program_loaded)
    );

    // Instruction Memory 
    instruction_memory_dynamic #(NUM_PE) instr_mem (
        .clk(clk),
        .reset(reset),
        .read_enable(read_enable),
        .PC(PC),
        .instruction(instruction),
        .last_instruction(last_instruction),
        .write_enable(write_enable & cluster_select),
        .write_address(write_address),
        .write_data(write_data)
    );

    //Cluster PE_system
    local_bus_top #(NUM_PE) cluster (
        .clk(clk),
        .reset(reset),
        .PCin(PCin),
        .Clusterid(Clusterid),
        .instructions(instructions),
        .mem_ack_global(mem_ack_global),
        .mem_data_global(mem_data_global),
        .mem_address_global(mem_address_global),
        .result_out(result_out),
        .mem_write_data_global(mem_write_data_global),
        .PCout(PCout),
        .IREnableExt(IREnableExt),
        .mem_write_global(mem_write_global),
        .mem_read_global(mem_read_global),
        .execution_complete(execution_complete),
        .branch_exec(branch_exec)
    );

endmodule
