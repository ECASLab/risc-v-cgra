`include "LocalBusNoController.v"

module local_bus_top_tb;

    parameter NUM_PE = 4;

    // Clock and reset
    reg clk;
    reg reset;

    // Inputs to local_bus_top
    reg [NUM_PE*32-1:0] PCin;
    reg [NUM_PE*32-1:0] instructions;
    reg mem_ack_global;
    reg [31:0] mem_data_global;

    // Outputs from local_bus_top
    wire [31:0] mem_address_global;
    wire [31:0] result_out;
    wire [31:0] mem_write_data_global;
    wire [NUM_PE*32-1:0] PCout;
    wire mem_write_global;
    wire mem_read_global;
    wire [NUM_PE-1:0] execution_complete;
    wire [NUM_PE-1:0] branch_exec;

    // Instantiate the DUT
    local_bus_top #(NUM_PE) dut (
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

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10ns clock period

    initial begin
        // Initialize inputs
        reset = 1;
        PCin = 0;
        instructions = 0;
        mem_ack_global = 0;
        mem_data_global = 32'h12345678;

        // Hold reset for a few cycles
        #20;
        reset = 0;

        // Stimulate PC and instruction inputs
        PCin = {
            32'h00000010,
            32'h00000020,
            32'h00000030,
            32'h00000040
        };

        instructions = {
            32'hA0000001, // Dummy opcodes
            32'hA0000002,
            32'hA0000003,
            32'hA0000004
        };

        // Simulate global memory acknowledgment
        #30;
        mem_ack_global = 1;

        // Observe outputs
        #50;
        $display("Global Mem Address: %h", mem_address_global);
        $display("Global Write Data: %h", mem_write_data_global);
        $display("Global Read Signal: %b", mem_read_global);
        $display("Global Write Signal: %b", mem_write_global);
        $display("Execution Complete Flags: %b", execution_complete);
        $display("Branch Exec Flags: %b", branch_exec);
        $display("PCout[0]: %h", PCout[0*32 +: 32]);

        // Finish simulation
        #50;
        $finish;
    end

endmodule
