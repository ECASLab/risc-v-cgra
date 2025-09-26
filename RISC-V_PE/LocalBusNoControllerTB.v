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
        // Dump waveform for debugging
        $dumpfile("tb_LocalBusNoController.vcd");
        $dumpvars(0, local_bus_top_tb);

        // Monitor outputs
        $monitor("Time: %0dns | mem_address_global: %b | result_out: %b | mem_write_data_global: %b | mem_write_global: %b | mem_read_global: %b | execution_complete: %b | branch_exec: %b | PCout: %b", 
                 $time, mem_address_global, result_out, mem_write_data_global, mem_write_global, mem_read_global, execution_complete, branch_exec, PCout);

        $display("Starting Local Bus testbench...");
        
        // Initialize signals
        reset = 1;
        PCin = 0;
        instructions = 32'h00000000;
        mem_ack_global = 0;

        #10;
        reset = 0;

        // Step 1: Write 4 local registers at a time
        $display ("##############################################################################");
        $display ("###################### Loading 4 non dependent values ########################");
        $display ("##############################################################################");
        instructions = 128'h00020283_00020203_00020183_00020103; // Load to registers 2, 3, 4 and 5
        PCin = 128'h00000003_00000002_00000001_00000000;

        #70

        #50

        //#30 // waiting for mem_read signal

        //#10

        //#10 //Need to sync grant signal with mem data or store the received memData
        //mem_data_global = 32'b00000000000000001000000000000010;
        //mem_ack_global = 1;

        //#10
        //mem_ack_global = 0;

        //#40 // waiting for rdWrite

        //#10

        // Finish simulation
        //#50;
        $finish;
    end

endmodule
