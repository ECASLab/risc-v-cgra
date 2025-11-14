`timescale 1ns / 1ps
`include "DataRegs.v"

module tb_register_system;

    // Testbench signals
    reg clk;
    reg reset;
    reg [4:0] selRD, selRS1, selRS2;
    reg reg_select;
    reg [31:0] data_in;
    reg rdwrite;
    reg read_en;
    wire [31:0] data_out1, data_out2;

    // Instantiate the register_system
    register_system uut (
        .clk(clk),
        .reset(reset),
        .selRD(selRD),
        .selRS1(selRS1),
        .selRS2(selRS2),
        .reg_select(reg_select),
        .data_in(data_in),
        .rdwrite(rdwrite),
        .read_en(read_en),
        .data_out1(data_out1),
        .data_out2(data_out2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock period = 10 time units
    end

    // Testbench logic
    initial begin
        // Dump waveforms for debugging
        $dumpfile("tb_register_system.vcd");
        $dumpvars(0, tb_register_system);

        // Initialize inputs
        reset = 1;
        selRD = 0; selRS1 = 0; selRS2 = 0; // Start with 0
        read_en = 0;
        reg_select = 1'b0; // Initially, only one output
        data_in = 0;
        rdwrite = 1'b0; // Write disabled initially

        // Reset the system
        #10 reset = 0;

        // Test Case 1: Write to Register 0
        selRD = 5'b00000; // Select register 0
        data_in = 32'hA5A5A5A5; // Data to write
        rdwrite = 1'b1; // Enable write
        #10;

        rdwrite = 1'b0;

        // Test Case 2: Write to Register 14
        #10;
        selRD = 5'b01110; // Select register 14
        data_in = 32'h5A5A5A5A; // Data to write
        rdwrite = 1'b1;
        #10;

        // Test Case 3: Read from Registers 0 and 15
        read_en = 1;
        rdwrite = 1'b0; // Disable write
        reg_select = 1'b1; // Enable both outputs
        selRS1 = 5'd0; // Read from register 0
        selRS2 = 5'b01110; // Read from register 14
        #10;
        $display("TC3 | data_out1=%h, data_out2=%h", data_out1, data_out2);

        // Test Case 4: Write to and Read from Register 31
        read_en = 0;
        selRD = 5'd31;
        data_in = 32'h12345678;
        rdwrite = 1'b1; // Enable write
        reg_select = 1'b0; // Only one output
        #10;
        rdwrite = 1'b0; // Disable write
        read_en = 1;
        selRS1 = 5'd31; // Read from register 31

        #10;
        $display("TC4 | data_out1=%h, data_out2=%h", data_out1, data_out2);

        // Test Case 5: Write to Register 12 and Read 2 of the previous registers
        selRD = 5'd12;
        read_en = 0;
        data_in = 32'h87654321;
        rdwrite = 1'b1; // Enable write
        reg_select = 1'b1; // Only one output
        #10;
        rdwrite = 1'b0; // Disable write
        read_en = 1;
        selRS1 = 5'd31; // Read from register 31
        selRS2 = 5'd12;
        
        #10;
        $display("TC5 | data_out1=%h | data_out2=%h", data_out1, data_out2);
        // Finish simulation
        #10 $finish;
    end

endmodule
