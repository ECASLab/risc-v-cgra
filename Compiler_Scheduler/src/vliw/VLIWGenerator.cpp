#include "VLIWGenerator.h"
#include "../utils/Logger.h"
#include <fstream>
#include <iomanip>
#include <sstream>
#include <algorithm>
#include <cstring>

// Constructor: inicializa generador VLIW con scheduler, parser y config
// Input: scheduler, parser, config (componentes del compilador)
// Output: instancia de VLIWGenerator con mapeos inicializados
VLIWGenerator::VLIWGenerator(const Scheduler& scheduler,
                             const Parser& parser,
                             const ConfigReader& config)
    : scheduler_(scheduler), parser_(parser), config_(config) {
    initializeOpcodeMappings();
    initializeRegisterMappings();
}

// Inicializa el mapeo de mnemonicos RISC-V a opcodes binarios de 7 bits según ISA estándar
// Input: ninguno
// Output: opcode_map_ poblado con todos los mnemonicos soportados
void VLIWGenerator::initializeOpcodeMappings() {
    // NOP (implementado como ADDI x0, x0, 0)
    opcode_map_["nop"]    = 0x13;  // 0010011 (I-type)
    
    // I-Type: 0010011 (addi, slti, sltiu, xori, ori, andi, slli, srli, srai)
    opcode_map_["addi"]   = 0x13;  // 0010011
    opcode_map_["slti"]   = 0x13;  // 0010011
    opcode_map_["sltiu"]  = 0x13;  // 0010011
    opcode_map_["xori"]   = 0x13;  // 0010011
    opcode_map_["ori"]    = 0x13;  // 0010011
    opcode_map_["andi"]   = 0x13;  // 0010011
    opcode_map_["slli"]   = 0x13;  // 0010011
    opcode_map_["srli"]   = 0x13;  // 0010011
    opcode_map_["srai"]   = 0x13;  // 0010011
    
    // R-Type: 0110011 (add, sub, sll, slt, sltu, xor, srl, sra, or, and, mul)
    opcode_map_["add"]    = 0x33;  // 0110011
    opcode_map_["sub"]    = 0x33;  // 0110011
    opcode_map_["sll"]    = 0x33;  // 0110011
    opcode_map_["slt"]    = 0x33;  // 0110011
    opcode_map_["sltu"]   = 0x33;  // 0110011
    opcode_map_["xor"]    = 0x33;  // 0110011
    opcode_map_["srl"]    = 0x33;  // 0110011
    opcode_map_["sra"]    = 0x33;  // 0110011
    opcode_map_["or"]     = 0x33;  // 0110011
    opcode_map_["and"]    = 0x33;  // 0110011
    opcode_map_["mul"]    = 0x33;  // 0110011
    
    // I-Type Load: 0000011 (lw, lh, lhu, lb, lbu)
    opcode_map_["lw"]     = 0x03;  // 0000011
    opcode_map_["lh"]     = 0x03;  // 0000011
    opcode_map_["lhu"]    = 0x03;  // 0000011
    opcode_map_["lb"]     = 0x03;  // 0000011
    opcode_map_["lbu"]    = 0x03;  // 0000011
    
    // S-Type: 0100011 (sw, sh, sb)
    opcode_map_["sw"]     = 0x23;  // 0100011
    opcode_map_["sh"]     = 0x23;  // 0100011
    opcode_map_["sb"]     = 0x23;  // 0100011
    
    // B-Type: 1100011 (beq, bne, blt, bge)
    opcode_map_["beq"]    = 0x63;  // 1100011
    opcode_map_["bne"]    = 0x63;  // 1100011
    opcode_map_["blt"]    = 0x63;  // 1100011
    opcode_map_["bge"]    = 0x63;  // 1100011
    
    // J-Type: 1101111 (jal)
    opcode_map_["jal"]    = 0x6F;  // 1101111
    
    // U-Type: 0110111 (lui)
    opcode_map_["lui"]    = 0x37;  // 0110111
}

// Inicializa el mapeo de nombres de registros a números de 5 bits (0-31)
// Input: ninguno
// Output: register_map_ poblado con nombres x0-x31 y ABI names
void VLIWGenerator::initializeRegisterMappings() {
    for (int i = 0; i < 32; i++) {
        register_map_["x" + std::to_string(i)] = i;
    }
    
    register_map_["zero"] = 0;
    register_map_["ra"]   = 1;
    register_map_["sp"]   = 2;
    register_map_["gp"]   = 3;
    register_map_["tp"]   = 4;
    register_map_["t0"]   = 5;
    register_map_["t1"]   = 6;
    register_map_["t2"]   = 7;
    register_map_["s0"]   = 8;  // fp
    register_map_["fp"]   = 8;
    register_map_["s1"]   = 9;
    register_map_["a0"]   = 10;
    register_map_["a1"]   = 11;
    register_map_["a2"]   = 12;
    register_map_["a3"]   = 13;
    register_map_["a4"]   = 14;
    register_map_["a5"]   = 15;
    register_map_["a6"]   = 16;
    register_map_["a7"]   = 17;
    register_map_["s2"]   = 18;
    register_map_["s3"]   = 19;
    register_map_["s4"]   = 20;
    register_map_["s5"]   = 21;
    register_map_["s6"]   = 22;
    register_map_["s7"]   = 23;
    register_map_["s8"]   = 24;
    register_map_["s9"]   = 25;
    register_map_["s10"]  = 26;
    register_map_["s11"]  = 27;
    register_map_["t3"]   = 28;
    register_map_["t4"]   = 29;
    register_map_["t5"]   = 30;
    register_map_["t6"]   = 31;
}

// Obtiene el opcode binario para un mnemonico RISC-V
// Input: mnemonic (nombre de la operación, ej: "add", "lw")
// Output: opcode de 7 bits (0-127) según ISA estándar o 0x13 (ADDI/NOP) si desconocido
uint8_t VLIWGenerator::getOpcode(const std::string& mnemonic) const {
    auto it = opcode_map_.find(mnemonic);
    if (it != opcode_map_.end()) {
        return it->second;
    }
    Logger::warning("Opcode desconocido: " + mnemonic + ", usando NOP (ADDI)");
    return 0x13;  // ADDI x0, x0, 0 (NOP)
}

// Obtiene el número de registro (0-31) para un nombre
// Input: reg_name (nombre del registro, ej: "x5", "a0", "sp")
// Output: número de registro de 5 bits o 0 si desconocido
uint8_t VLIWGenerator::getRegisterNumber(const std::string& reg_name) const {
    if (reg_name.empty() || reg_name == "-") {
        return 0;
    }
    
    auto it = register_map_.find(reg_name);
    if (it != register_map_.end()) {
        return it->second;
    }
    
    Logger::warning("Registro desconocido: " + reg_name + ", usando x0");
    return 0;
}

// Obtiene funct3 para una instrucción según el ISA
uint8_t VLIWGenerator::getFunct3(const std::string& mnemonic) const {
    // I-Type arithmetic/logic
    if (mnemonic == "addi") return 0x0;
    if (mnemonic == "slti") return 0x2;
    if (mnemonic == "sltiu") return 0x3;
    if (mnemonic == "xori") return 0x4;
    if (mnemonic == "ori") return 0x6;
    if (mnemonic == "andi") return 0x7;
    if (mnemonic == "slli") return 0x1;
    if (mnemonic == "srli") return 0x5;
    if (mnemonic == "srai") return 0x5;
    
    // R-Type
    if (mnemonic == "add" || mnemonic == "sub" || mnemonic == "mul") return 0x0;
    if (mnemonic == "sll") return 0x1;
    if (mnemonic == "slt") return 0x2;
    if (mnemonic == "sltu") return 0x3;
    if (mnemonic == "xor") return 0x4;
    if (mnemonic == "srl" || mnemonic == "sra") return 0x5;
    if (mnemonic == "or") return 0x6;
    if (mnemonic == "and") return 0x7;
    
    // Load
    if (mnemonic == "lb") return 0x0;
    if (mnemonic == "lh") return 0x1;
    if (mnemonic == "lw") return 0x2;
    if (mnemonic == "lbu") return 0x4;
    if (mnemonic == "lhu") return 0x5;
    
    // Store
    if (mnemonic == "sb") return 0x0;
    if (mnemonic == "sh") return 0x1;
    if (mnemonic == "sw") return 0x2;
    
    // Branch
    if (mnemonic == "beq") return 0x0;
    if (mnemonic == "bne") return 0x1;
    if (mnemonic == "blt") return 0x4;
    if (mnemonic == "bge") return 0x5;
    
    return 0x0;
}

// Obtiene funct7 para una instrucción R-Type según el ISA
uint8_t VLIWGenerator::getFunct7(const std::string& mnemonic) const {
    if (mnemonic == "sub") return 0x20;
    if (mnemonic == "sra") return 0x20;
    if (mnemonic == "srai") return 0x20;
    if (mnemonic == "mul") return 0x01;
    return 0x00;
}

// Retorna codificación de NOP (todos los bits en 0)
uint32_t VLIWGenerator::encodeNOP() const {
    return 0x00000000;
}

// Codifica una instrucción RISC-V a 32 bits según formato ISA estándar
// Input: sched_inst (instrucción planificada con ID, PE, ciclo)
// Output: palabra de 32 bits en formato R, I, S, B, U o J según tipo
uint32_t VLIWGenerator::encodeInstruction(const ScheduledInstruction& sched_inst) const {
    const auto& instructions = parser_.getInstructions();
    if (sched_inst.instruction_id >= static_cast<int>(instructions.size())) {
        Logger::error("ID de instrucción fuera de rango: " + std::to_string(sched_inst.instruction_id));
        return encodeNOP();
    }
    
    const Instruction& inst = instructions[sched_inst.instruction_id];
    std::string mnemonic = inst.getOpcode();
    
    uint32_t encoding = 0;
    uint8_t opcode = getOpcode(mnemonic) & 0x7F;  // 7 bits
    uint8_t funct3 = getFunct3(mnemonic) & 0x7;   // 3 bits
    uint8_t funct7 = getFunct7(mnemonic) & 0x7F;  // 7 bits
    
    uint8_t rd = getRegisterNumber(inst.getRd()) & 0x1F;
    uint8_t rs1 = getRegisterNumber(inst.getRs1()) & 0x1F;
    uint8_t rs2 = getRegisterNumber(inst.getRs2()) & 0x1F;
    int32_t imm = inst.hasImmediateValue() ? inst.getImmediate() : 0;
    
    // Opcode siempre en bits [6:0]
    encoding |= static_cast<uint32_t>(opcode);
    
    // R-Type: funct7[31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | rd[11:7] | opcode[6:0]
    if (opcode == 0x33) {  // R-Type
        encoding |= (static_cast<uint32_t>(rd) << 7);
        encoding |= (static_cast<uint32_t>(funct3) << 12);
        encoding |= (static_cast<uint32_t>(rs1) << 15);
        encoding |= (static_cast<uint32_t>(rs2) << 20);
        encoding |= (static_cast<uint32_t>(funct7) << 25);
    }
    // I-Type: imm[31:20] | rs1[19:15] | funct3[14:12] | rd[11:7] | opcode[6:0]
    else if (opcode == 0x13 || opcode == 0x03) {  // I-Type (ALU, Load)
        encoding |= (static_cast<uint32_t>(rd) << 7);
        encoding |= (static_cast<uint32_t>(funct3) << 12);
        encoding |= (static_cast<uint32_t>(rs1) << 15);
        
        // Para shifts inmediatos, funct7 va en bits [31:25] y shamt en [24:20]
        if (mnemonic == "slli" || mnemonic == "srli" || mnemonic == "srai") {
            uint32_t shamt = imm & 0x1F;
            encoding |= (shamt << 20);
            encoding |= (static_cast<uint32_t>(funct7) << 25);
        } else {
            // Inmediato de 12 bits con signo
            uint32_t imm12 = static_cast<uint32_t>(imm) & 0xFFF;
            encoding |= (imm12 << 20);
        }
    }
    // S-Type: imm[11:5][31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | imm[4:0][11:7] | opcode[6:0]
    else if (opcode == 0x23) {  // S-Type (Store)
        uint32_t imm_4_0 = static_cast<uint32_t>(imm) & 0x1F;
        uint32_t imm_11_5 = (static_cast<uint32_t>(imm) >> 5) & 0x7F;
        
        encoding |= (imm_4_0 << 7);
        encoding |= (static_cast<uint32_t>(funct3) << 12);
        encoding |= (static_cast<uint32_t>(rs1) << 15);
        encoding |= (static_cast<uint32_t>(rs2) << 20);
        encoding |= (imm_11_5 << 25);
    }
    // B-Type: imm[12|10:5][31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | imm[4:1|11][11:7] | opcode[6:0]
    else if (opcode == 0x63) {  // B-Type (Branch)
        uint32_t imm_u = static_cast<uint32_t>(imm);
        uint32_t imm_11 = (imm_u >> 11) & 0x1;
        uint32_t imm_4_1 = (imm_u >> 1) & 0xF;
        uint32_t imm_10_5 = (imm_u >> 5) & 0x3F;
        uint32_t imm_12 = (imm_u >> 12) & 0x1;
        
        encoding |= ((imm_11 << 7) | (imm_4_1 << 8));
        encoding |= (static_cast<uint32_t>(funct3) << 12);
        encoding |= (static_cast<uint32_t>(rs1) << 15);
        encoding |= (static_cast<uint32_t>(rs2) << 20);
        encoding |= ((imm_10_5 << 25) | (imm_12 << 31));
    }
    // U-Type: imm[31:12] | rd[11:7] | opcode[6:0]
    else if (opcode == 0x37) {  // U-Type (LUI)
        encoding |= (static_cast<uint32_t>(rd) << 7);
        uint32_t imm_31_12 = (static_cast<uint32_t>(imm) >> 12) & 0xFFFFF;
        encoding |= (imm_31_12 << 12);
    }
    // J-Type: imm[20|10:1|11|19:12][31:12] | rd[11:7] | opcode[6:0]
    else if (opcode == 0x6F) {  // J-Type (JAL)
        encoding |= (static_cast<uint32_t>(rd) << 7);
        uint32_t imm_u = static_cast<uint32_t>(imm);
        uint32_t imm_19_12 = (imm_u >> 12) & 0xFF;
        uint32_t imm_11 = (imm_u >> 11) & 0x1;
        uint32_t imm_10_1 = (imm_u >> 1) & 0x3FF;
        uint32_t imm_20 = (imm_u >> 20) & 0x1;
        
        encoding |= ((imm_19_12 << 12) | (imm_11 << 20) | (imm_10_1 << 21) | (imm_20 << 31));
    }
    
    return encoding;
}

// Genera secuencia de palabras VLIW de 128 bits a partir del schedule
// Input: ninguno (usa scheduler_ interno)
// Output: vliw_instructions_ con una palabra por ciclo (4 PEs × 32 bits)
void VLIWGenerator::generate() {
    Logger::info("Generando instrucciones VLIW de 128 bits (4 PEs × 32 bits)...");
    
    vliw_instructions_.clear();
    
    const auto& schedule = scheduler_.getSchedule();
    if (schedule.empty()) {
        Logger::warning("Schedule vacío, no se generaron instrucciones VLIW");
        return;
    }
    
    int makespan = scheduler_.getMakespan();
    Logger::info("Makespan: " + std::to_string(makespan) + " ciclos");
    
    std::map<int, std::vector<ScheduledInstruction>> instructions_by_cycle;
    for (const auto& sched_inst : schedule) {
        instructions_by_cycle[sched_inst.cycle].push_back(sched_inst);
    }
    
    for (int cycle = 0; cycle < makespan; cycle++) {
        VLIWInstruction vliw;
        vliw.cycle = cycle;
        
        vliw.pe0_encoding = encodeNOP();
        vliw.pe1_encoding = encodeNOP();
        vliw.pe2_encoding = encodeNOP();
        vliw.pe3_encoding = encodeNOP();
        
        if (instructions_by_cycle.find(cycle) != instructions_by_cycle.end()) {
            for (const auto& sched_inst : instructions_by_cycle[cycle]) {
                uint32_t encoding = encodeInstruction(sched_inst);
                
                switch (sched_inst.pe_id) {
                    case 0:
                        vliw.pe0_encoding = encoding;
                        break;
                    case 1:
                        vliw.pe1_encoding = encoding;
                        break;
                    case 2:
                        vliw.pe2_encoding = encoding;
                        break;
                    case 3:
                        vliw.pe3_encoding = encoding;
                        break;
                    default:
                        Logger::warning("PE ID inválido: " + std::to_string(sched_inst.pe_id));
                        break;
                }
            }
        }
        
        vliw_instructions_.push_back(vliw);
    }
    
    Logger::info("Generadas " + std::to_string(vliw_instructions_.size()) + " palabras VLIW de 128 bits");
}

// Decodifica palabra de 32 bits a string assembly legible según ISA estándar
// Input: encoding (palabra de 32 bits codificada)
// Output: string con instrucción en formato assembly
std::string VLIWGenerator::decodeToString(uint32_t encoding) const {
    if (encoding == 0) {
        return "nop";
    }
    
    uint8_t opcode = extractOpcode(encoding);
    uint8_t rd = extractRd(encoding);
    uint8_t rs1 = extractRs1(encoding);
    uint8_t rs2 = extractRs2(encoding);
    uint8_t funct3 = (encoding >> 12) & 0x7;
    uint8_t funct7 = (encoding >> 25) & 0x7F;
    int16_t imm = extractImmediate(encoding);
    
    std::string mnemonic = "unknown";
    
    // Determinar el mnemonic basado en opcode, funct3 y funct7
    if (opcode == 0x33) {  // R-Type
        if (funct7 == 0x00) {
            if (funct3 == 0x0) mnemonic = "add";
            else if (funct3 == 0x1) mnemonic = "sll";
            else if (funct3 == 0x2) mnemonic = "slt";
            else if (funct3 == 0x3) mnemonic = "sltu";
            else if (funct3 == 0x4) mnemonic = "xor";
            else if (funct3 == 0x5) mnemonic = "srl";
            else if (funct3 == 0x6) mnemonic = "or";
            else if (funct3 == 0x7) mnemonic = "and";
        } else if (funct7 == 0x20) {
            if (funct3 == 0x0) mnemonic = "sub";
            else if (funct3 == 0x5) mnemonic = "sra";
        } else if (funct7 == 0x01) {
            if (funct3 == 0x0) mnemonic = "mul";
            else if (funct3 == 0x1) mnemonic = "mulh";
            else if (funct3 == 0x2) mnemonic = "mulhsu";
            else if (funct3 == 0x3) mnemonic = "mulhu";
        }
    } else if (opcode == 0x13) {  // I-Type ALU
        if (funct3 == 0x0) mnemonic = "addi";
        else if (funct3 == 0x2) mnemonic = "slti";
        else if (funct3 == 0x3) mnemonic = "sltiu";
        else if (funct3 == 0x4) mnemonic = "xori";
        else if (funct3 == 0x6) mnemonic = "ori";
        else if (funct3 == 0x7) mnemonic = "andi";
        else if (funct3 == 0x1) mnemonic = "slli";
        else if (funct3 == 0x5) {
            if (funct7 == 0x00) mnemonic = "srli";
            else if (funct7 == 0x20) mnemonic = "srai";
        }
    } else if (opcode == 0x03) {  // Load
        if (funct3 == 0x0) mnemonic = "lb";
        else if (funct3 == 0x1) mnemonic = "lh";
        else if (funct3 == 0x2) mnemonic = "lw";
        else if (funct3 == 0x4) mnemonic = "lbu";
        else if (funct3 == 0x5) mnemonic = "lhu";
    } else if (opcode == 0x23) {  // Store
        if (funct3 == 0x0) mnemonic = "sb";
        else if (funct3 == 0x1) mnemonic = "sh";
        else if (funct3 == 0x2) mnemonic = "sw";
    } else if (opcode == 0x63) {  // Branch
        if (funct3 == 0x0) mnemonic = "beq";
        else if (funct3 == 0x1) mnemonic = "bne";
        else if (funct3 == 0x4) mnemonic = "blt";
        else if (funct3 == 0x5) mnemonic = "bge";
    } else if (opcode == 0x6F) {
        mnemonic = "jal";
    } else if (opcode == 0x37) {
        mnemonic = "lui";
    }
    
    std::string rd_name = "x" + std::to_string(rd);
    std::string rs1_name = "x" + std::to_string(rs1);
    std::string rs2_name = "x" + std::to_string(rs2);
    
    for (const auto& pair : register_map_) {
        if (pair.second == rd && pair.first.find("x") != 0) rd_name = pair.first;
        if (pair.second == rs1 && pair.first.find("x") != 0) rs1_name = pair.first;
        if (pair.second == rs2 && pair.first.find("x") != 0) rs2_name = pair.first;
    }
    
    std::ostringstream oss;
    oss << mnemonic;
    
    // B-Type: beq rs1, rs2, offset
    if (opcode == 0x63) {
        oss << " " << rs1_name << ", " << rs2_name << ", " << imm;
    }
    // S-Type: sw rs2, offset(rs1)
    else if (opcode == 0x23) {
        oss << " " << rs2_name << ", " << imm << "(" << rs1_name << ")";
    }
    // Load I-Type: lw rd, offset(rs1)
    else if (opcode == 0x03) {
        oss << " " << rd_name << ", " << imm << "(" << rs1_name << ")";
    }
    // U-Type: lui rd, imm
    else if (opcode == 0x37) {
        oss << " " << rd_name << ", " << imm;
    }
    // J-Type: jal rd, offset
    else if (opcode == 0x6F) {
        oss << " " << rd_name << ", " << imm;
    }
    // R-Type: add rd, rs1, rs2
    else if (opcode == 0x33) {
        oss << " " << rd_name << ", " << rs1_name << ", " << rs2_name;
    }
    // I-Type ALU: addi rd, rs1, imm
    else if (opcode == 0x13) {
        oss << " " << rd_name << ", " << rs1_name << ", " << imm;
    }
    
    return oss.str();
}

uint8_t VLIWGenerator::extractOpcode(uint32_t encoding) const {
    return encoding & 0x7F;  // bits [6:0]
}

uint8_t VLIWGenerator::extractRd(uint32_t encoding) const {
    return (encoding >> 7) & 0x1F;  // bits [11:7]
}

uint8_t VLIWGenerator::extractRs1(uint32_t encoding) const {
    return (encoding >> 15) & 0x1F;  // bits [19:15]
}

uint8_t VLIWGenerator::extractRs2(uint32_t encoding) const {
    return (encoding >> 20) & 0x1F;  // bits [24:20]
}

int16_t VLIWGenerator::extractImmediate(uint32_t encoding) const {
    uint8_t opcode = extractOpcode(encoding);
    
    // I-Type: bits [31:20]
    if (opcode == 0x13 || opcode == 0x03 || opcode == 0x67) {
        int32_t imm = static_cast<int32_t>(encoding) >> 20;  // Sign extend
        return static_cast<int16_t>(imm & 0xFFF);
    }
    // S-Type: bits [31:25][11:7]
    else if (opcode == 0x23) {
        int32_t imm_11_5 = (encoding >> 25) & 0x7F;
        int32_t imm_4_0 = (encoding >> 7) & 0x1F;
        int32_t imm = (imm_11_5 << 5) | imm_4_0;
        // Sign extend from bit 11
        if (imm & 0x800) imm |= 0xFFFFF000;
        return static_cast<int16_t>(imm);
    }
    // B-Type: bits [31][7][30:25][11:8] << 1
    else if (opcode == 0x63) {
        int32_t imm_12 = (encoding >> 31) & 0x1;
        int32_t imm_11 = (encoding >> 7) & 0x1;
        int32_t imm_10_5 = (encoding >> 25) & 0x3F;
        int32_t imm_4_1 = (encoding >> 8) & 0xF;
        int32_t imm = (imm_12 << 12) | (imm_11 << 11) | (imm_10_5 << 5) | (imm_4_1 << 1);
        // Sign extend from bit 12
        if (imm & 0x1000) imm |= 0xFFFFE000;
        return static_cast<int16_t>(imm);
    }
    // U-Type: bits [31:12]
    else if (opcode == 0x37 || opcode == 0x17) {
        return static_cast<int16_t>((encoding >> 12) & 0xFFFFF);
    }
    // J-Type: bits [31][19:12][20][30:21] << 1
    else if (opcode == 0x6F) {
        int32_t imm_20 = (encoding >> 31) & 0x1;
        int32_t imm_19_12 = (encoding >> 12) & 0xFF;
        int32_t imm_11 = (encoding >> 20) & 0x1;
        int32_t imm_10_1 = (encoding >> 21) & 0x3FF;
        int32_t imm = (imm_20 << 20) | (imm_19_12 << 12) | (imm_11 << 11) | (imm_10_1 << 1);
        // Sign extend from bit 20
        if (imm & 0x100000) imm |= 0xFFE00000;
        return static_cast<int16_t>(imm);
    }
    
    return 0;
}

void VLIWGenerator::saveBinaryFile(const std::string& filename) const {
    std::ofstream file(filename, std::ios::binary);
    if (!file.is_open()) {
        Logger::error("No se pudo abrir archivo para escritura: " + filename);
        return;
    }
    
    for (const auto& vliw : vliw_instructions_) {
        // Escribir en orden little-endian: PE0, PE1, PE2, PE3
        file.write(reinterpret_cast<const char*>(&vliw.pe0_encoding), sizeof(uint32_t));
        file.write(reinterpret_cast<const char*>(&vliw.pe1_encoding), sizeof(uint32_t));
        file.write(reinterpret_cast<const char*>(&vliw.pe2_encoding), sizeof(uint32_t));
        file.write(reinterpret_cast<const char*>(&vliw.pe3_encoding), sizeof(uint32_t));
    }
    
    file.close();
    Logger::info("Archivo binario guardado: " + filename);
}

void VLIWGenerator::saveHexFileConcatenated(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo abrir archivo para escritura: " + filename);
        return;
    }
    
    file << "# VLIW Instruction Memory (128 bits = 32 bits × 4 PEs)\n";
    file << "# Format: [PE3:PE2:PE1:PE0] (PE0 = LSB, PE3 = MSB) - CONCATENATED\n";
    file << "# Each PE instruction: 32-bit RISC-V ISA Standard Format\n";
    file << "# Opcode is in bits [6:0], format varies by type (R/I/S/B/U/J)\n";
    file << "#\n";
    file << "# Total VLIW words: " << vliw_instructions_.size() << "\n";
    file << "#\n\n";
    
    for (size_t i = 0; i < vliw_instructions_.size(); i++) {
        const auto& vliw = vliw_instructions_[i];
        
        file << std::hex << std::uppercase << std::setfill('0');
        file << std::setw(8) << vliw.pe3_encoding
             << std::setw(8) << vliw.pe2_encoding
             << std::setw(8) << vliw.pe1_encoding
             << std::setw(8) << vliw.pe0_encoding << "\n";
        file << std::dec;
    }
    
    file.close();
    Logger::info("Archivo hexadecimal concatenado guardado: " + filename);
}

void VLIWGenerator::saveHexFileSeparated(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo abrir archivo para escritura: " + filename);
        return;
    }
    
    file << "# VLIW Instruction Memory (128 bits = 32 bits × 4 PEs)\n";
    file << "# Format: One instruction per line - SEPARATED\n";
    file << "# Each PE instruction: 32-bit RISC-V ISA Standard Format\n";
    file << "# Opcode is in bits [6:0], format varies by type (R/I/S/B/U/J)\n";
    file << "#\n";
    file << "# Total VLIW words: " << vliw_instructions_.size() << "\n";
    file << "# Total instructions: " << (vliw_instructions_.size() * 4) << "\n";
    file << "#\n\n";
    
    for (size_t i = 0; i < vliw_instructions_.size(); i++) {
        const auto& vliw = vliw_instructions_[i];
        
        file << std::hex << std::uppercase << std::setfill('0');
        file << std::setw(8) << vliw.pe3_encoding << "\n";
        file << std::setw(8) << vliw.pe2_encoding << "\n";
        file << std::setw(8) << vliw.pe1_encoding << "\n";
        file << std::setw(8) << vliw.pe0_encoding << "\n";
        file << std::dec;
    }
    
    file.close();
    Logger::info("Archivo hexadecimal separado guardado: " + filename);
}

void VLIWGenerator::saveVerilogMemFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo abrir archivo para escritura: " + filename);
        return;
    }
    
    file << "// VLIW Instruction Memory for Verilog $readmemh\n";
    file << "// 128-bit words (4 PEs × 32 bits)\n";
    file << "// Format: PE3_PE2_PE1_PE0 (PE0 = LSB)\n";
    file << "// Total words: " << vliw_instructions_.size() << "\n\n";
    
    for (const auto& vliw : vliw_instructions_) {
        file << std::hex << std::uppercase << std::setfill('0');
        file << std::setw(8) << vliw.pe3_encoding
             << std::setw(8) << vliw.pe2_encoding
             << std::setw(8) << vliw.pe1_encoding
             << std::setw(8) << vliw.pe0_encoding << "\n";
    }
    
    file.close();
    Logger::info("Archivo Verilog guardado: " + filename);
}

void VLIWGenerator::saveDetailedFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo abrir archivo para escritura: " + filename);
        return;
    }
    
    file << "╔════════════════════════════════════════════════════════════════╗\n";
    file << "║         VLIW INSTRUCTION MEMORY - DETAILED VIEW                ║\n";
    file << "╚════════════════════════════════════════════════════════════════╝\n\n";
    
    file << "Configuration:\n";
    file << "  VLIW Width: 128 bits (4 PEs × 32 bits)\n";
    file << "  PE Encoding: 32 bits RISC-V ISA Standard Format\n";
    file << "    R-Type: [31:25]=funct7 [24:20]=rs2 [19:15]=rs1 [14:12]=funct3 [11:7]=rd [6:0]=opcode\n";
    file << "    I-Type: [31:20]=imm[11:0] [19:15]=rs1 [14:12]=funct3 [11:7]=rd [6:0]=opcode\n";
    file << "    S-Type: [31:25]=imm[11:5] [24:20]=rs2 [19:15]=rs1 [14:12]=funct3 [11:7]=imm[4:0] [6:0]=opcode\n";
    file << "    B-Type: [31]=imm[12] [30:25]=imm[10:5] [24:20]=rs2 [19:15]=rs1 [14:12]=funct3 [11:8]=imm[4:1] [7]=imm[11] [6:0]=opcode\n";
    file << "    U-Type: [31:12]=imm[31:12] [11:7]=rd [6:0]=opcode\n";
    file << "    J-Type: [31]=imm[20] [30:21]=imm[10:1] [20]=imm[11] [19:12]=imm[19:12] [11:7]=rd [6:0]=opcode\n";
    file << "  Bit Layout: [PE3(127:96):PE2(95:64):PE1(63:32):PE0(31:0)]\n";
    file << "  Total Words: " << vliw_instructions_.size() << "\n\n";
    
    file << std::string(80, '=') << "\n\n";
    
    for (const auto& vliw : vliw_instructions_) {
        file << "CYCLE " << std::setw(3) << vliw.cycle << ":\n";
        file << std::string(80, '-') << "\n";
        
        // PE0 (bits 31:0)
        file << "  PE0 [31:0]:   0x" << std::hex << std::uppercase << std::setfill('0') 
             << std::setw(8) << vliw.pe0_encoding << " | " 
             << decodeToString(vliw.pe0_encoding) << "\n";
        
        // PE1 (bits 63:32)
        file << "  PE1 [63:32]:  0x" << std::setw(8) << vliw.pe1_encoding << " | "
             << decodeToString(vliw.pe1_encoding) << "\n";
        
        // PE2 (bits 95:64)
        file << "  PE2 [95:64]:  0x" << std::setw(8) << vliw.pe2_encoding << " | "
             << decodeToString(vliw.pe2_encoding) << "\n";
        
        // PE3 (bits 127:96)
        file << "  PE3 [127:96]: 0x" << std::setw(8) << vliw.pe3_encoding << " | "
             << decodeToString(vliw.pe3_encoding) << "\n";
        
        file << std::dec;
        
        // Palabra completa de 128 bits
        file << "\n  Full 128-bit word: 0x" << std::hex << std::uppercase 
             << std::setw(8) << vliw.pe3_encoding
             << std::setw(8) << vliw.pe2_encoding
             << std::setw(8) << vliw.pe1_encoding
             << std::setw(8) << vliw.pe0_encoding << "\n";
        file << std::dec;
        file << "\n";
    }
    
    file.close();
    Logger::info("Archivo detallado guardado: " + filename);
}

VLIWGenerator::Statistics VLIWGenerator::calculateStatistics() const {
    Statistics stats;
    stats.total_vliw_words = vliw_instructions_.size();
    stats.total_operations = 0;
    stats.nop_count = 0;
    
    for (const auto& vliw : vliw_instructions_) {
        // Contar operaciones por PE
        if (vliw.pe0_encoding != 0) {
            stats.total_operations++;
            uint8_t op = extractOpcode(vliw.pe0_encoding);
            std::string mnemonic = "unknown";
            for (const auto& pair : opcode_map_) {
                if (pair.second == op) {
                    mnemonic = pair.first;
                    break;
                }
            }
            stats.operation_histogram[mnemonic]++;
        } else {
            stats.nop_count++;
        }
        
        if (vliw.pe1_encoding != 0) {
            stats.total_operations++;
            uint8_t op = extractOpcode(vliw.pe1_encoding);
            std::string mnemonic = "unknown";
            for (const auto& pair : opcode_map_) {
                if (pair.second == op) {
                    mnemonic = pair.first;
                    break;
                }
            }
            stats.operation_histogram[mnemonic]++;
        } else {
            stats.nop_count++;
        }
        
        if (vliw.pe2_encoding != 0) {
            stats.total_operations++;
            uint8_t op = extractOpcode(vliw.pe2_encoding);
            std::string mnemonic = "unknown";
            for (const auto& pair : opcode_map_) {
                if (pair.second == op) {
                    mnemonic = pair.first;
                    break;
                }
            }
            stats.operation_histogram[mnemonic]++;
        } else {
            stats.nop_count++;
        }
        
        if (vliw.pe3_encoding != 0) {
            stats.total_operations++;
            uint8_t op = extractOpcode(vliw.pe3_encoding);
            std::string mnemonic = "unknown";
            for (const auto& pair : opcode_map_) {
                if (pair.second == op) {
                    mnemonic = pair.first;
                    break;
                }
            }
            stats.operation_histogram[mnemonic]++;
        } else {
            stats.nop_count++;
        }
    }
    
    int total_slots = stats.total_vliw_words * 4;  // 4 PEs
    stats.utilization = total_slots > 0 ? 
        (static_cast<double>(stats.total_operations) / total_slots * 100.0) : 0.0;
    
    return stats;
}

void VLIWGenerator::printStatistics() const {
    Statistics stats = calculateStatistics();
    
    std::cout << "\n╔════════════════════════════════════════════════════════════════╗\n";
    std::cout << "║              VLIW GENERATION STATISTICS                        ║\n";
    std::cout << "╚════════════════════════════════════════════════════════════════╝\n\n";
    
    std::cout << "VLIW Configuration:\n";
    std::cout << "  Word Width: 128 bits (4 PEs × 32 bits)\n";
    std::cout << "  PE Instruction Format: RISC-V ISA Standard 32-bit\n";
    std::cout << "    Opcode: [6:0] (7 bits)\n";
    std::cout << "    Format varies by instruction type:\n";
    std::cout << "      R-Type: funct7[31:25] rs2[24:20] rs1[19:15] funct3[14:12] rd[11:7] op[6:0]\n";
    std::cout << "      I-Type: imm[31:20] rs1[19:15] funct3[14:12] rd[11:7] op[6:0]\n";
    std::cout << "      S-Type: imm[31:25] rs2[24:20] rs1[19:15] funct3[14:12] imm[11:7] op[6:0]\n";
    std::cout << "      B-Type: imm[12|10:5][31:25] rs2[24:20] rs1[19:15] funct3[14:12] imm[4:1|11][11:7] op[6:0]\n";
    std::cout << "      U-Type: imm[31:12] rd[11:7] op[6:0]\n";
    std::cout << "      J-Type: imm[20|10:1|11|19:12][31:12] rd[11:7] op[6:0]\n\n";
    
    std::cout << "Generated Code:\n";
    std::cout << "  Total VLIW Words: " << stats.total_vliw_words << "\n";
    std::cout << "  Total Operations: " << stats.total_operations << "\n";
    std::cout << "  Total NOPs: " << stats.nop_count << "\n";
    std::cout << "  Total Slots: " << (stats.total_vliw_words * 4) << " (4 PEs)\n";
    std::cout << "  Utilization: " << std::fixed << std::setprecision(2) 
              << stats.utilization << "%\n\n";
    
    if (!stats.operation_histogram.empty()) {
        std::cout << "Operation Distribution:\n";
        for (const auto& pair : stats.operation_histogram) {
            std::cout << "  " << std::setw(12) << std::left << pair.first 
                      << ": " << std::setw(5) << std::right << pair.second << "\n";
        }
    }
    
    std::cout << "\n";
}

void VLIWGenerator::saveAssemblyFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo abrir archivo para escritura: " + filename);
        return;
    }
    
    file << "# ========================================================\n";
    file << "# VLIW ASSEMBLY OUTPUT\n";
    file << "# Generated by CGRA Compiler Phase 4\n";
    file << "# ========================================================\n";
    file << "#\n";
    file << "# Architecture: 4-way VLIW (4 PEs)\n";
    file << "# Instruction Width: 128 bits (32 bits per PE)\n";
    file << "# Format: PE0 (LSB) | PE1 | PE2 | PE3 (MSB)\n";
    file << "#\n";
    file << "# Encoding: RISC-V ISA Standard 32-bit Format\n";
    file << "# - Opcode in bits [6:0] (7 bits)\n";
    file << "# - Format varies by instruction type (R/I/S/B/U/J)\n";
    file << "#\n\n";
    
    file << ".section .text\n";
    file << ".global _start\n\n";
    file << "_start:\n\n";
    
    int active_cycles = 0;
    int total_ops = 0;
    
    for (const auto& vliw : vliw_instructions_) {
        // Contar operaciones activas en este ciclo
        int ops_in_cycle = 0;
        if (vliw.pe0_encoding != 0) ops_in_cycle++;
        if (vliw.pe1_encoding != 0) ops_in_cycle++;
        if (vliw.pe2_encoding != 0) ops_in_cycle++;
        if (vliw.pe3_encoding != 0) ops_in_cycle++;
        
        if (ops_in_cycle > 0) {
            active_cycles++;
            total_ops += ops_in_cycle;
        }
        
        file << "    # ==================== CYCLE " << std::setw(3) << vliw.cycle 
             << " ==================== (" << ops_in_cycle << " ops)\n";
        
        // PE0
        file << "    # PE0: ";
        if (vliw.pe0_encoding != 0) {
            file << decodeToString(vliw.pe0_encoding) << "\n";
            file << "    .word 0x" << std::hex << std::uppercase << std::setfill('0') 
                 << std::setw(8) << vliw.pe0_encoding << std::dec << "    # PE0 [31:0]\n";
        } else {
            file << "nop\n";
            file << "    .word 0x00000000    # PE0 [31:0] - NOP\n";
        }
        
        // PE1
        file << "    # PE1: ";
        if (vliw.pe1_encoding != 0) {
            file << decodeToString(vliw.pe1_encoding) << "\n";
            file << "    .word 0x" << std::hex << std::uppercase << std::setfill('0') 
                 << std::setw(8) << vliw.pe1_encoding << std::dec << "    # PE1 [63:32]\n";
        } else {
            file << "nop\n";
            file << "    .word 0x00000000    # PE1 [63:32] - NOP\n";
        }
        
        // PE2
        file << "    # PE2: ";
        if (vliw.pe2_encoding != 0) {
            file << decodeToString(vliw.pe2_encoding) << "\n";
            file << "    .word 0x" << std::hex << std::uppercase << std::setfill('0') 
                 << std::setw(8) << vliw.pe2_encoding << std::dec << "    # PE2 [95:64]\n";
        } else {
            file << "nop\n";
            file << "    .word 0x00000000    # PE2 [95:64] - NOP\n";
        }
        
        // PE3
        file << "    # PE3: ";
        if (vliw.pe3_encoding != 0) {
            file << decodeToString(vliw.pe3_encoding) << "\n";
            file << "    .word 0x" << std::hex << std::uppercase << std::setfill('0') 
                 << std::setw(8) << vliw.pe3_encoding << std::dec << "    # PE3 [127:96]\n";
        } else {
            file << "nop\n";
            file << "    .word 0x00000000    # PE3 [127:96] - NOP\n";
        }
        
        file << "\n";
    }
    
    file << "\n# ========================================================\n";
    file << "# STATISTICS\n";
    file << "# ========================================================\n";
    file << "# Total Cycles: " << vliw_instructions_.size() << "\n";
    file << "# Active Cycles: " << active_cycles << "\n";
    file << "# Total Operations: " << total_ops << "\n";
    file << "# Average IPC: " << std::fixed << std::setprecision(2) 
         << (vliw_instructions_.size() > 0 ? static_cast<double>(total_ops) / vliw_instructions_.size() : 0.0) << "\n";
    file << "# Utilization: " << std::fixed << std::setprecision(2)
         << (vliw_instructions_.size() > 0 ? static_cast<double>(total_ops) / (vliw_instructions_.size() * 4) * 100.0 : 0.0) << "%\n";
    
    file.close();
    Logger::info("Archivo assembly guardado: " + filename);
}

void VLIWGenerator::saveELFFile(const std::string& filename) const {
    std::ofstream file(filename, std::ios::binary);
    if (!file.is_open()) {
        Logger::error("No se pudo abrir archivo para escritura: " + filename);
        return;
    }
    
    // ELF Header (52 bytes para 32-bit)
    // Magic number
    file.put(0x7F);
    file.put('E');
    file.put('L');
    file.put('F');
    
    // Class (32-bit = 1)
    file.put(1);
    
    // Data encoding (little-endian = 1)
    file.put(1);
    
    // ELF version
    file.put(1);
    
    // OS/ABI (SYSV = 0)
    file.put(0);
    
    // ABI version + padding (8 bytes)
    for (int i = 0; i < 8; i++) file.put(0);
    
    // Type (Executable = 2)
    file.put(2);
    file.put(0);
    
    // Machine (RISC-V = 0xF3 = 243)
    file.put(0xF3);
    file.put(0x00);
    
    // Version
    uint32_t version = 1;
    file.write(reinterpret_cast<const char*>(&version), 4);
    
    // Entry point address (0x00000000)
    uint32_t entry = 0x00000000;
    file.write(reinterpret_cast<const char*>(&entry), 4);
    
    // Program header offset (52 bytes después del header)
    uint32_t phoff = 52;
    file.write(reinterpret_cast<const char*>(&phoff), 4);
    
    // Section header offset (después de program header + data)
    uint32_t data_size = vliw_instructions_.size() * 16; // 16 bytes por VLIW word
    uint32_t shoff = 52 + 32 + data_size; // header + program header + data
    file.write(reinterpret_cast<const char*>(&shoff), 4);
    
    // Flags (RISC-V specific)
    uint32_t flags = 0x00000005; // RVC + Float ABI soft
    file.write(reinterpret_cast<const char*>(&flags), 4);
    
    // ELF header size
    uint16_t ehsize = 52;
    file.write(reinterpret_cast<const char*>(&ehsize), 2);
    
    // Program header entry size
    uint16_t phentsize = 32;
    file.write(reinterpret_cast<const char*>(&phentsize), 2);
    
    // Number of program headers
    uint16_t phnum = 1;
    file.write(reinterpret_cast<const char*>(&phnum), 2);
    
    // Section header entry size
    uint16_t shentsize = 40;
    file.write(reinterpret_cast<const char*>(&shentsize), 2);
    
    // Number of section headers
    uint16_t shnum = 2; // NULL + .text
    file.write(reinterpret_cast<const char*>(&shnum), 2);
    
    // Section header string table index
    uint16_t shstrndx = 1;
    file.write(reinterpret_cast<const char*>(&shstrndx), 2);
    
    // Program Header (32 bytes)
    // Type (PT_LOAD = 1)
    uint32_t p_type = 1;
    file.write(reinterpret_cast<const char*>(&p_type), 4);
    
    // Offset in file
    uint32_t p_offset = 52 + 32; // Después de ELF header + program header
    file.write(reinterpret_cast<const char*>(&p_offset), 4);
    
    // Virtual address
    uint32_t p_vaddr = 0x00000000;
    file.write(reinterpret_cast<const char*>(&p_vaddr), 4);
    
    // Physical address
    uint32_t p_paddr = 0x00000000;
    file.write(reinterpret_cast<const char*>(&p_paddr), 4);
    
    // Size in file
    file.write(reinterpret_cast<const char*>(&data_size), 4);
    
    // Size in memory
    file.write(reinterpret_cast<const char*>(&data_size), 4);
    
    // Flags (R+X = 5)
    uint32_t p_flags = 5;
    file.write(reinterpret_cast<const char*>(&p_flags), 4);
    
    // Alignment
    uint32_t p_align = 0x1000;
    file.write(reinterpret_cast<const char*>(&p_align), 4);
    
    // VLIW Data Section
    for (const auto& vliw : vliw_instructions_) {
        // Escribir en orden little-endian: PE0, PE1, PE2, PE3
        file.write(reinterpret_cast<const char*>(&vliw.pe0_encoding), 4);
        file.write(reinterpret_cast<const char*>(&vliw.pe1_encoding), 4);
        file.write(reinterpret_cast<const char*>(&vliw.pe2_encoding), 4);
        file.write(reinterpret_cast<const char*>(&vliw.pe3_encoding), 4);
    }
    
    // Section Headers
    // NULL section (40 bytes of zeros)
    for (int i = 0; i < 40; i++) file.put(0);
    
    // .text section header
    uint32_t sh_name = 1; // offset in string table
    file.write(reinterpret_cast<const char*>(&sh_name), 4);
    
    uint32_t sh_type = 1; // SHT_PROGBITS
    file.write(reinterpret_cast<const char*>(&sh_type), 4);
    
    uint32_t sh_flags = 6; // SHF_ALLOC | SHF_EXECINSTR
    file.write(reinterpret_cast<const char*>(&sh_flags), 4);
    
    uint32_t sh_addr = 0x00000000;
    file.write(reinterpret_cast<const char*>(&sh_addr), 4);
    
    uint32_t sh_offset = p_offset;
    file.write(reinterpret_cast<const char*>(&sh_offset), 4);
    
    uint32_t sh_size = data_size;
    file.write(reinterpret_cast<const char*>(&sh_size), 4);
    
    uint32_t sh_link = 0;
    file.write(reinterpret_cast<const char*>(&sh_link), 4);
    
    uint32_t sh_info = 0;
    file.write(reinterpret_cast<const char*>(&sh_info), 4);
    
    uint32_t sh_addralign = 16;
    file.write(reinterpret_cast<const char*>(&sh_addralign), 4);
    
    uint32_t sh_entsize = 0;
    file.write(reinterpret_cast<const char*>(&sh_entsize), 4);
    
    file.close();
    Logger::info("Archivo ELF guardado: " + filename);
}

void VLIWGenerator::saveAllFormats(const std::string& output_dir, const std::string& base_name) const {
    saveBinaryFile(output_dir + "/" + base_name + ".bin");
    saveHexFileConcatenated(output_dir + "/" + base_name + "_concatenated.hex");
    saveHexFileSeparated(output_dir + "/" + base_name + "_separated.hex");
    saveVerilogMemFile(output_dir + "/" + base_name + ".mem");
    saveDetailedFile(output_dir + "/" + base_name + "_detailed.txt");
    saveAssemblyFile(output_dir + "/" + base_name + ".s");
    saveELFFile(output_dir + "/" + base_name + ".elf");
}
