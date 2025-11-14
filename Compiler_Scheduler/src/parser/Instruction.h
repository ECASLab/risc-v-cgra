#ifndef INSTRUCTION_H
#define INSTRUCTION_H

#include <string>
#include <vector>

// Tipos de instrucción RISC-V
enum class InstructionType {
    R_TYPE, I_TYPE, S_TYPE, B_TYPE, J_TYPE, U_TYPE,
    LABEL, DIRECTIVE, UNKNOWN
};

// Representa una instrucción RISC-V parseada
class Instruction {
private:
    std::string rawLine;
    int lineNumber;

    InstructionType type;
    std::string opcode;

    std::string rd, rs1, rs2;
    int immediate;
    bool hasImmediate;

    std::string label;
    int offset;

    bool isLabel;
    std::string labelName;

public:
    Instruction();
    Instruction(const std::string& line, int lineNum);

    InstructionType getType() const { return type; }
    std::string getOpcode() const { return opcode; }
    std::string getRd() const { return rd; }
    std::string getRs1() const { return rs1; }
    std::string getRs2() const { return rs2; }
    int getImmediate() const { return immediate; }
    bool hasImmediateValue() const { return hasImmediate; }
    std::string getLabel() const { return label; }
    int getOffset() const { return offset; }
    bool getIsLabel() const { return isLabel; }
    std::string getLabelName() const { return labelName; }
    std::string getRawLine() const { return rawLine; }
    int getLineNumber() const { return lineNumber; }

    bool isMemoryOperation() const;
    bool isLoadOperation() const;
    bool isStoreOperation() const;
    bool isBranchOperation() const;
    bool isJumpOperation() const;
    bool isALUOperation() const;
    bool readsRegister(const std::string& reg) const;
    bool writesRegister(const std::string& reg) const;

    std::string toString() const;
    void parse();

private:
    void determineType();
    void parseRType();
    void parseIType();
    void parseSType();
    void parseBType();
    void parseJType();
    void parseUType();
    std::vector<std::string> tokenize(const std::string& str) const;
    std::string trim(const std::string& str) const;
};

#endif // INSTRUCTION_H
