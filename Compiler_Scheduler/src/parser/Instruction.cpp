#include "Instruction.h"
#include "../utils/Logger.h"
#include <sstream>
#include <algorithm>
#include <cctype>

// Constructor por defecto: inicializa instrucción vacía
Instruction::Instruction()
: lineNumber(0), type(InstructionType::UNKNOWN),
immediate(0), hasImmediate(false), offset(0), isLabel(false) {}

// Constructor con línea de texto: parsea automáticamente la instrucción
// Input: line (línea de texto), lineNum (número de línea)
// Output: instancia de Instruction parseada
Instruction::Instruction(const std::string& line, int lineNum)
: rawLine(line), lineNumber(lineNum), type(InstructionType::UNKNOWN),
immediate(0), hasImmediate(false), offset(0), isLabel(false) {
    parse();
}

// Parsea la línea de texto y extrae opcode, registros, inmediatos, etc.
// Input: ninguno (usa rawLine interno)
// Output: campos de instrucción poblados (opcode, rd, rs1, rs2, immediate)
void Instruction::parse() {
    std::string cleaned = trim(rawLine);

    if (cleaned.empty() || cleaned[0] == '#') {
        return;
    }

    size_t commentPos = cleaned.find('#');
    if (commentPos != std::string::npos) {
        cleaned = cleaned.substr(0, commentPos);
        cleaned = trim(cleaned);
    }

    if (cleaned.back() == ':') {
        isLabel = true;
        type = InstructionType::LABEL;
        labelName = cleaned.substr(0, cleaned.length() - 1);
        return;
    }

    if (cleaned[0] == '.') {
        type = InstructionType::DIRECTIVE;
        opcode = cleaned;
        return;
    }

    std::vector<std::string> tokens = tokenize(cleaned);
    if (tokens.empty()) return;

    opcode = tokens[0];

    std::transform(opcode.begin(), opcode.end(), opcode.begin(), ::tolower);

    determineType();

    switch (type) {
        case InstructionType::R_TYPE: parseRType(); break;
        case InstructionType::I_TYPE: parseIType(); break;
        case InstructionType::S_TYPE: parseSType(); break;
        case InstructionType::B_TYPE: parseBType(); break;
        case InstructionType::J_TYPE: parseJType(); break;
        case InstructionType::U_TYPE: parseUType(); break;
        default: break;
    }
}

// Determina el tipo de instrucción RISC-V basado en el opcode
// Input: ninguno (usa opcode interno)
// Output: establece campo type (R_TYPE, I_TYPE, S_TYPE, etc.)
void Instruction::determineType() {
    if (opcode == "add" || opcode == "sub" || opcode == "mul" || opcode == "multiply" ||
        opcode == "and" || opcode == "or" || opcode == "xor" ||
        opcode == "sll" || opcode == "srl" || opcode == "sra" ||
        opcode == "slt" || opcode == "sltu") {
        type = InstructionType::R_TYPE;
        }
        else if (opcode == "lw" || opcode == "lb" || opcode == "lh" ||
            opcode == "lbu" || opcode == "lhu") {
            type = InstructionType::I_TYPE;
            }
            else if (opcode == "addi" || opcode == "slti" || opcode == "sltiu" ||
                opcode == "xori" || opcode == "ori" || opcode == "andi" ||
                opcode == "slli" || opcode == "srli" || opcode == "srai") {
                type = InstructionType::I_TYPE;
                }
                else if (opcode == "jalr") {
                    type = InstructionType::I_TYPE;
                }
                else if (opcode == "sw" || opcode == "sb" || opcode == "sh") {
                    type = InstructionType::S_TYPE;
                }
                else if (opcode == "beq" || opcode == "bne" || opcode == "blt" ||
                    opcode == "bge" || opcode == "bltu" || opcode == "bgeu") {
                    type = InstructionType::B_TYPE;
                    }
                    else if (opcode == "jal") {
                        type = InstructionType::J_TYPE;
                    }
                    else if (opcode == "lui" || opcode == "auipc") {
                        type = InstructionType::U_TYPE;
                    }
                    else {
                        type = InstructionType::UNKNOWN;
                        Logger::warning("Unknown opcode: " + opcode);
                    }
}

// Parsea instrucción R-Type (formato: opcode rd, rs1, rs2)
// Input: ninguno (usa rawLine interno)
// Output: establece rd, rs1, rs2
void Instruction::parseRType() {
    std::vector<std::string> tokens = tokenize(rawLine);
    if (tokens.size() >= 4) {
        rd = tokens[1];
        rs1 = tokens[2];
        rs2 = tokens[3];

        rd.erase(remove(rd.begin(), rd.end(), ','), rd.end());
        rs1.erase(remove(rs1.begin(), rs1.end(), ','), rs1.end());
        rs2.erase(remove(rs2.begin(), rs2.end(), ','), rs2.end());
    }
}

// Parsea instrucción I-Type (loads: lw rd, offset(rs1); ALU: addi rd, rs1, imm)
// Input: ninguno (usa rawLine interno)
// Output: establece rd, rs1, immediate
void Instruction::parseIType() {
    std::vector<std::string> tokens = tokenize(rawLine);

    if (isLoadOperation()) {
        if (tokens.size() >= 3) {
            rd = tokens[1];
            rd.erase(remove(rd.begin(), rd.end(), ','), rd.end());

            std::string memAccess = tokens[2];
            size_t parenPos = memAccess.find('(');
            if (parenPos != std::string::npos) {
                std::string offsetStr = memAccess.substr(0, parenPos);
                immediate = offsetStr.empty() ? 0 : std::stoi(offsetStr);
                hasImmediate = true;

                size_t closePos = memAccess.find(')');
                rs1 = memAccess.substr(parenPos + 1, closePos - parenPos - 1);
            }
        }
    } else {
        if (tokens.size() >= 4) {
            rd = tokens[1];
            rs1 = tokens[2];

            rd.erase(remove(rd.begin(), rd.end(), ','), rd.end());
            rs1.erase(remove(rs1.begin(), rs1.end(), ','), rs1.end());

            immediate = std::stoi(tokens[3]);
            hasImmediate = true;
        }
    }
}

// Parsea instrucción S-Type (formato: sw rs2, offset(rs1))
// Input: ninguno (usa rawLine interno)
// Output: establece rs1, rs2, immediate
void Instruction::parseSType() {
    std::vector<std::string> tokens = tokenize(rawLine);
    if (tokens.size() >= 3) {
        rs2 = tokens[1];
        rs2.erase(remove(rs2.begin(), rs2.end(), ','), rs2.end());

        std::string memAccess = tokens[2];
        size_t parenPos = memAccess.find('(');
        if (parenPos != std::string::npos) {
            std::string offsetStr = memAccess.substr(0, parenPos);
            immediate = offsetStr.empty() ? 0 : std::stoi(offsetStr);
            hasImmediate = true;

            size_t closePos = memAccess.find(')');
            rs1 = memAccess.substr(parenPos + 1, closePos - parenPos - 1);
        }
    }
}

// Parsea instrucción B-Type (formato: beq rs1, rs2, label)
// Input: ninguno (usa rawLine interno)
// Output: establece rs1, rs2, label
void Instruction::parseBType() {
    std::vector<std::string> tokens = tokenize(rawLine);
    if (tokens.size() >= 4) {
        rs1 = tokens[1];
        rs2 = tokens[2];
        label = tokens[3];

        rs1.erase(remove(rs1.begin(), rs1.end(), ','), rs1.end());
        rs2.erase(remove(rs2.begin(), rs2.end(), ','), rs2.end());
    }
}

// Parsea instrucción J-Type (formato: jal rd, label)
// Input: ninguno (usa rawLine interno)
// Output: establece rd, label
void Instruction::parseJType() {
    std::vector<std::string> tokens = tokenize(rawLine);
    if (tokens.size() >= 3) {
        rd = tokens[1];
        label = tokens[2];
        rd.erase(remove(rd.begin(), rd.end(), ','), rd.end());
    } else if (tokens.size() == 2) {
        rd = "x1";
        label = tokens[1];
    }
}

// Parsea instrucción U-Type (formato: lui rd, imm)
// Input: ninguno (usa rawLine interno)
// Output: establece rd, immediate
void Instruction::parseUType() {
    std::vector<std::string> tokens = tokenize(rawLine);
    if (tokens.size() >= 3) {
        rd = tokens[1];
        rd.erase(remove(rd.begin(), rd.end(), ','), rd.end());
        immediate = std::stoi(tokens[2]);
        hasImmediate = true;
    }
}

// Divide string en tokens separados por espacios
// Input: str (string a tokenizar)
// Output: vector de tokens
std::vector<std::string> Instruction::tokenize(const std::string& str) const {
    std::vector<std::string> tokens;
    std::istringstream iss(str);
    std::string token;
    while (iss >> token) {
        tokens.push_back(token);
    }
    return tokens;
}

// Elimina espacios al inicio y final del string
// Input: str (string a limpiar)
// Output: string sin espacios en extremos
std::string Instruction::trim(const std::string& str) const {
    size_t first = str.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) return "";
    size_t last = str.find_last_not_of(" \t\r\n");
    return str.substr(first, last - first + 1);
}

bool Instruction::isMemoryOperation() const {
    return isLoadOperation() || isStoreOperation();
}

bool Instruction::isLoadOperation() const {
    return opcode == "lw" || opcode == "lb" || opcode == "lh" ||
    opcode == "lbu" || opcode == "lhu";
}

bool Instruction::isStoreOperation() const {
    return opcode == "sw" || opcode == "sb" || opcode == "sh";
}

bool Instruction::isBranchOperation() const {
    return type == InstructionType::B_TYPE;
}

bool Instruction::isJumpOperation() const {
    return type == InstructionType::J_TYPE || opcode == "jalr";
}

bool Instruction::isALUOperation() const {
    return type == InstructionType::R_TYPE ||
    (type == InstructionType::I_TYPE && !isMemoryOperation() && !isJumpOperation());
}

bool Instruction::readsRegister(const std::string& reg) const {
    return rs1 == reg || rs2 == reg;
}

bool Instruction::writesRegister(const std::string& reg) const {
    return rd == reg;
}

std::string Instruction::toString() const {
    std::stringstream ss;
    ss << "[Line " << lineNumber << "] ";

    if (isLabel) {
        ss << "LABEL: " << labelName;
    } else {
        ss << opcode;
        if (!rd.empty()) ss << " rd=" << rd;
        if (!rs1.empty()) ss << " rs1=" << rs1;
        if (!rs2.empty()) ss << " rs2=" << rs2;
        if (hasImmediate) ss << " imm=" << immediate;
        if (!label.empty()) ss << " label=" << label;
    }

    return ss.str();
}
