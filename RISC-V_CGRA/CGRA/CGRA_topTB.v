`timescale 1ns / 1ps

module tb_cgra_top;

    parameter NUM_CLUSTERS = 4;
    parameter NUM_PE = 4;
    parameter MEM_DEPTH = 256;

    reg clk;
    reg reset;

    // Instantiate CGRA
    cgra_top #(
        .NUM_CLUSTERS(NUM_CLUSTERS),
        .NUM_PE(NUM_PE),
        .MEM_DEPTH(MEM_DEPTH)
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        $display("Starting CGRA top-level testbench...");
        clk = 0;
        reset = 1;
        #20;

        reset = 0;

        // Wait for dispatcher to complete
        wait (dut.dispatch_done);
        $display("Instruction dispatch complete.");


        #500;

        // Wait for all clusters to signal done
        //wait (&dut.done_all);
        //$display("All clusters completed execution.");

        // Observe memory transactions
        //#50;
        //$display("Global memory address: %h", dut.mem_address_global);
        //$display("Global memory write data: %h", dut.mem_write_data_global);
        //$display("Global memory read data: %h", dut.mem_data_global);
        //$display("Global memory read enable: %b", dut.mem_read_global);
        //$display("Global memory write enable: %b", dut.mem_write_global);

        $display("Testbench complete.");
        $finish;
    end
endmodule
