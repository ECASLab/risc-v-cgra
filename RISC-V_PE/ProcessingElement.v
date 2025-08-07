// Procesing element top module
`include "Control.v"
`include "decoder.v"
`include "ALU.v"
`include "mux2_1.v"
`include "mux3_1.v"
`include "reg.v"

module processing_element (
    input clk,
    input [31:0] PCin,         // Program counter coming from bus, into muxA and into controller
    input [31:0] instruction,  // Input instruction to IR            
    input mem_ack,             // Memory acknowledgment signal from bus
    input data_Ready,          // Data ready signal from bus
    input [31:0] AmuxIn,       // Data from bus local memory to be loaded into A mux
    input [31:0] BmuxIn,       // Data from bus local memory to be loaded into B mux
    input [31:0] memData,      // Data from global memory to be loaded to A mux
    input        reset,
    input [1:0] id,            // Unique id for the PE
    output [31:0] mem_address, // Address for memory operations (store)
    output reg_select,         // Signal to select proper register to read
    output mem_read,           // Memory read signal     
    output [4:0] rs1Out,       // Register Address to be read
    output [4:0] rs2Out,      
    output [4:0] rdOut,
    output rdWrite,
    output mem_write,
    output [31:0] result_out,  // Output selected from output mux
    output read_en,            // Read enable to take data from rs1 and rs2
    output [31:0] PCout,
    output        execution_complete,
    output        branch_exec,  //Indicates a branch operation is requested  
    output [2:0]  secondRead    //Indicates to interface that more time is needed for the second read in store functions 
);

    // Internal signals

    // Signals from decoder
    wire [6:0] op;                 // Opcode from instruction
    wire [2:0] funct3;             // Function code from instruction
    wire [6:0] funct7;             // Function code for selection
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [11:0] imm12;
    wire [19:0] immhi;
    wire decodeComplete;
    wire [31:0] instructionIn;     // From IR

    // Signals from controller
    wire [31:0] ALURes;
    wire ALUcomplete;
    wire ALU0;
    wire [1:0] Osel;
    wire [1:0] Asel;
    wire [1:0] Bsel;
    wire [4:0] ALUsel;
    wire reg_reset;
    wire [31:0] immvalue;
    wire Aenable;
    wire Benable;
    wire IRenable;

    // Signals from mux and registers
    wire [31:0] Aval;          // Operand A value from muxA to reg
    wire [31:0] Bval;          // Operand B value from muxB to reg

    wire [31:0] opA;            // Signal from register output to ALU
    wire [31:0] opB;            // Signal from register output to ALU

    // Instantiate the controller module
    controller ctrl (
        .clk(clk),
        .ALU0(ALU0),
        .op(op),
        .funct3(funct3),
        .funct7(funct7),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm12(imm12),
        .immhi(immhi),
        .ALUcomplete(ALUcomplete),
        .ALURes(ALURes),
        .decodeComplete(decodeComplete),
        .PCin(PCin),
        .PCout(PCout),
        .dataReady(data_Ready),
        .mem_ack(mem_ack),
        .reg_reset(reg_reset),
        .ALUsel(ALUsel),
        .Asel(Asel),
        .Bsel(Bsel),
        .Osel(Osel),
        .immvalue(immvalue),
        .Aenable(Aenable),
        .Benable(Benable),
        .IRenable(IRenable),
        .reg_select(reg_select),
        .mem_address(mem_address),
        .rs1Out(rs1Out),
        .rs2Out(rs2Out),
        .rdOut(rdOut),
        .rdWrite(rdWrite),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .read_en(read_en),
        .reset(reset),
        .execution_complete(execution_complete),
        .branch_exec(branch_exec),
        .secondRead(secondRead)
    );

    // Instantiate the register modules A, B and IR
    Register regA (
        .clock(clk),
        .reset(reg_reset),
        .r_enable(Aenable), 
        .data_in(Aval), 
        .data_out(opA) 
    );

    Register regB (
        .clock(clk),
        .reset(reg_reset),
        .r_enable(Benable), 
        .data_in(Bval), 
        .data_out(opB)
    );

    Register regIR (
        .clock(clk),
        .reset(reg_reset),
        .r_enable(IRenable), 
        .data_in(instruction), 
        .data_out(instructionIn)
    );  

    // Instantiate decoder
    decoder deco (
        .instruction(instructionIn),
        .op(op),
        .funct3(funct3),
        .funct7(funct7),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm12(imm12),
        .immhi(immhi),
        .decodeComplete(decodeComplete)
    );

    // Instantiate ALU module
    alu alu (
        .clk(clk),
        .A(opA), 
        .B(opB), 
        .ALU_Sel(ALUsel), 
        .ALU_Out(ALURes),  // Output result from ALU operation.
        .Zero(ALU0),
        .ALUcomplete(ALUcomplete),
        .reset(reg_reset)
    );

    // Instantiate MUXes 
    mux3_1 muxA (
        .in_1(memData), 
        .in_2(AmuxIn), 
        .in_3(PCin),
        .sel(Asel), 
        .data_out(Aval)  // Output to be used as operand A.
    );

    mux3_1 muxB (
        .in_1(32'b0), 
        .in_2(BmuxIn), 
        .in_3(immvalue),
        .sel(Bsel), 
        .data_out(Bval)  // Output to be used as operand B.
    );

    mux3_1 muxOut (
        .in_1(ALURes), 
        .in_2(opA), 
        .in_3(opB), 
        .sel(Osel),  
        .data_out(result_out)  // Output message register.
    );

endmodule
