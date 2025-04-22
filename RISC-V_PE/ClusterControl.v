//Cluster controller

module cluster_controller (
    input clk,                     // Clock signal
    input reset,                   // Reset signal
    //signals for instruction memory
    input [127:0] instruction_mem, // Instructions from instruction memory for each PE
    output reg [31:0] PCsIM,        // Program counter to read from instruction memory
    output reg [3:0] InstReadEn,   // Read enable signals for instruction memory 

    output reg [127:0] PCinPE,  // Program counter inputs to PEs
    output reg [127:0] instruction_outPE, // Instructions to load into PEs
    input [127:0] PCoutPE,           // Program counter outputs from PEs
    input [3:0] execution_complete,
    input last_instruction  //Input from instruction memory that last instruction was read
    );

    // Internal variables
    reg [31:0] current_pc;    // Current program counters for the last executed instruction
    reg program_start;        //Signal to initialize first instruction fetch
    reg [3:0] dependency;     //Dependency flags
    reg [127:0] instructionTemp; //Temporary instruction for loading less than 4 instructions
    reg [127:0] PCinTemp;  //Temporary PCin for loading less than 4 instructions
    reg end_execute;   //Signal to stop fetching instructions

    function [14:0] register_extraction;
        input [31:0] instruction;
        reg [6:0] opcode;            // Temporary register for opcode
        reg [4:0] rd, rs1, rs2;
        begin
            opcode = 7'b0;
            opcode = instruction[6:0]; // Extract opcode (bits [6:0])
            rd = 5'b0;
            rs1 = 5'b0;
            rs2 = 5'b0;

            case (opcode)
            7'b0110011: //Type R
            begin
                rd = instruction[11:7];
                rs1 = instruction[19:15];
                rs2 = instruction[24:20];
            end
            7'b1101111, 7'b0110111: //Types U and J
            begin
                rd = instruction[11:7];
            end
            7'b0100011, 7'b1100011: // Types S and B
            begin
                rs1 = instruction[19:15];
                rs2 = instruction[24:20];
            end
            7'b0000011, 7'b0010011: //Type I
            begin
                $display("Instruction: %b", instruction);
                rd = instruction[11:7];
                rs1 = instruction[19:15];
                $display("Rs1: %b and Rd: %b", rs1, rd);
            end
            endcase
            // Concatenate rd, rs1, rs2 into a single output
            register_extraction = {rd, rs1, rs2};
        end
    endfunction
    
    // Function definition 
    task dependency_check;
        input [127:0] instructions;
        output [3:0] dependency_flags; 
        reg [14:0] regs1, regs2, regs3, regs4; // Decoded {rd, rs1, rs2} for each instruction
        reg [4:0] rdop1, rs1op1, rs2op1; // Instruction 1: rd, rs1, rs2
        reg [4:0] rdop2, rs1op2, rs2op2; // Instruction 2: rd, rs1, rs2
        reg [4:0] rdop3, rs1op3, rs2op3; // Instruction 3: rd, rs1, rs2
        reg [4:0] rdop4, rs1op4, rs2op4; // Instruction 4: rd, rs1, rs2
        begin
            // Decode registers for all 4 instructions
            regs1 = register_extraction(instructions[31:0]);   // Instruction 1
            regs2 = register_extraction(instructions[63:32]);  // Instruction 2
            regs3 = register_extraction(instructions[95:64]);  // Instruction 3
            regs4 = register_extraction(instructions[127:96]); // Instruction 4

            // Extract rd, rs1, rs2 for each instruction
            rdop1 = regs1[14:10]; rs1op1 = regs1[9:5]; rs2op1 = regs1[4:0];
            rdop2 = regs2[14:10]; rs1op2 = regs2[9:5]; rs2op2 = regs2[4:0];
            rdop3 = regs3[14:10]; rs1op3 = regs3[9:5]; rs2op3 = regs3[4:0];
            rdop4 = regs4[14:10]; rs1op4 = regs4[9:5]; rs2op4 = regs4[4:0];

            $display("Rs1op1: %b, Rs2op1: %b, Rdop1: %b", rs1op1, rs2op1, rdop1);
            $display("Rs1op2: %b, Rs2op2: %b, Rdop2: %b", rs1op2, rs2op2, rdop2);
            $display("Rs1op3: %b, Rs2op3: %b, Rdop3: %b", rs1op3, rs2op3, rdop3);
            $display("Rs1op4: %b, Rs2op4: %b, Rdop4: %b", rs1op4, rs2op4, rdop4);

            // Reset dependency flags
            dependency_flags = 4'b0000;

            if (((rs1op2 == rdop1) || (rs2op2 == rdop1) || (rs1op2 == rs1op1) || (rs2op2 == rs1op1) || (rs1op2 == rs2op1) || (rs2op2 == rs2op1)) && (rs1op2 != 0) && (rs2op2 != 0))
            begin
                dependency_flags = dependency_flags | 4'b0010;
            end
            if (((rs1op3 == rdop1) || (rs1op3 == rdop2) || (rs2op3 == rdop1) || (rs2op3 == rdop2)|| (rs1op3 == rs1op1) || (rs1op3 == rs1op2) || (rs2op3 == rs1op1) || (rs2op3 == rs1op2) || (rs1op3 == rs2op1) || (rs1op3 == rs2op2) || (rs2op3 == rs2op1) || (rs2op3 == rs2op2)) && (rs1op3 != 0) && (rs2op3 != 0))
            begin
                dependency_flags = dependency_flags | 4'b0100;
            end
            if (((rs1op4 == rdop1) || (rs1op4 == rdop2) || (rs1op4 == rdop3) || (rs2op4 == rdop1) || (rs2op4 == rdop2) || (rs2op4 == rdop3) || (rs1op4 == rs1op1) || (rs1op4 == rs1op2)  || (rs1op4 == rs1op3) || (rs2op4 == rs1op1) || (rs2op4 == rs1op2) || (rs2op4 == rs1op3) || (rs1op4 == rs2op1) || (rs1op4 == rs2op2) || (rs1op4 == rs2op3) || (rs2op4 == rs2op1) || (rs2op4 == rs2op2) || (rs2op4 == rs2op3)) && (rs1op4 != 0) && (rs2op4 != 0))
            begin
                dependency_flags = dependency_flags | 4'b1000;
            end
        end
    endtask

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all state
            current_pc <= 32'b0;
            PCinPE <= 128'b0;
            PCsIM <= 32'b0;
            InstReadEn <= 4'b0;
            instruction_outPE <= 128'b0;
            program_start <= 1;
            dependency <= 4'b0;
            instructionTemp <= 128'b0;
            PCinTemp <= 128'b0;
            end_execute <= 0;
        end 
        else begin
            // Program counter and instruction loading assuming program has more than 4 instructions
            if (program_start)
            begin
                $display("Program started");
                PCsIM <= 32'h00000000; //Read the first instruction in the program
                InstReadEn <= 4'b1111;
                instructionTemp <= 0;
                dependency <= 0;
                if (instruction_mem != 0)
                begin
                    $display("Read instructions from memory");
                    InstReadEn <= 0;
                    dependency_check(instruction_mem, dependency);
                    $display("Dependency: %b", dependency);
                    if (dependency == 0) //There is no dependency
                    begin
                        $display("No dependency");
                        instruction_outPE = instruction_mem;
                        PCinPE = {PCsIM+32'd3, PCsIM+32'd2, PCsIM+32'd1, PCsIM};
                        current_pc = 32'd4;
                        $display("Instructions written to PEs: %h", instruction_outPE);
                        $display("Current PC: %b", current_pc);
                    end
                    else 
                    begin
                        instructionTemp[31:0] = instruction_mem[31:0];
                        PCinTemp[31:0] = PCsIM;
                        if (dependency[1] == 1'b1)
                        begin
                            $display("There is dependency on the second operation");
                            $display("Will only load instruction 0");
                            current_pc = 32'd1;
                        end 
                        else if (dependency[2] == 1'b1)
                        begin
                            $display("There is dependency on the third operation");
                            $display("Will only load instructions 0 adn 1");
                            instructionTemp[63:32] = instruction_mem[63:32];
                            PCinTemp[63:32] = PCsIM+1;
                            current_pc = 32'd2;
                        end
                        else if (dependency[3] == 1'b1)
                        begin
                            $display("There is dependency on the fourth operation");
                            $display("Will only load instructions 0, 1 and 2");
                            instructionTemp[95:64] = instruction_mem[95:64];
                            PCinTemp[95:64] = PCsIM+2;
                            current_pc = 32'd3;
                        end
                        instruction_outPE = instructionTemp;
                        PCinPE = PCinTemp;
                        $display("Instructions written to PEs: %h", instruction_outPE);
                        $display("Current PC: %b", current_pc);
                    end
                    program_start <= 0;
                end
            end
            else
            begin
                if (execution_complete != 0)
                begin
                    if (PCoutPE != PCinPE) //Means there was a break or jump
                    begin
                        if (PCoutPE[31:0] != PCinPE[31:0]) //Break comes from first operation
                        begin
                            current_pc = PCoutPE[31:0];
                        end
                        else if (PCoutPE[63:32] != PCinPE[63:32]) //Break comes from second operation
                        begin
                            current_pc = PCoutPE[63:32];
                        end
                        else if (PCoutPE[95:64] != PCinPE[95:64]) //Break comes from third operation
                        begin
                            current_pc = PCoutPE[95:64];
                        end
                        else  //Break comes from fourth operation
                        begin
                            current_pc = PCoutPE[127:96];
                        end
                    end
                    else if (!end_execute)
                    begin
                        PCsIM = current_pc;
                        InstReadEn <= 4'b1111;
                        instructionTemp <= 0;
                        dependency <= 0;
                        if (instruction_mem != 0)
                        begin
                            InstReadEn <= 0;
                            dependency_check(instruction_mem, dependency);
                            $display("Dependency: %b", dependency);
                            if (dependency == 0)
                            begin
                                $display("No dependency");
                                instruction_outPE <= instruction_mem;
                                PCinPE <= {PCsIM+32'd3, PCsIM+32'd2, PCsIM+32'd1, PCsIM};
                                current_pc <= current_pc + 4;
                            end
                            else 
                            begin
                                instructionTemp[31:0] = instruction_mem[31:0];
                                PCinTemp[31:0] = PCsIM;
                                if (dependency[1] == 1'b1)
                                begin
                                    $display("There is dependency on the second operation");
                                    $display("Will only load instruction 0");
                                    current_pc = current_pc + 1;
                                end 
                                else if (dependency[2] == 1'b1)
                                begin
                                    $display("There is dependency on the third operation");
                                    $display("Will only load instructions 0 adn 1");
                                    instructionTemp[63:32] = instruction_mem[63:32];
                                    PCinTemp[63:32] = PCsIM+1;
                                    current_pc = current_pc + 2;
                                end
                                else if (dependency[3] == 1'b1)
                                begin
                                    $display("There is dependency on the fourth operation");
                                    $display("Will only load instructions 0, 1 and 2");
                                    instructionTemp[95:64] = instruction_mem[95:64];
                                    PCinTemp[95:64] = PCsIM+2;
                                    current_pc = current_pc + 3;
                                end
                                instruction_outPE <= instructionTemp;
                                PCinPE <= PCinTemp;
                            end
                            if (last_instruction)
                            begin
                                $display("The last instruction has been read");
                                end_execute <= 1;
                            end
                        end
                    end
                end
            end
        end
    end
endmodule
