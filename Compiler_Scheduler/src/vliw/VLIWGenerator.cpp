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

// Inicializa el mapeo de mnemonicos RISC-V a opcodes binarios de 6 bits
// Input: ninguno
// Output: opcode_map_ poblado con todos los mnemonicos soportados
void VLIWGenerator::initializeOpcodeMappings() {
    opcode_map_["nop"]    = 0x00;
    
    opcode_map_["addi"]   = 0x01;
    opcode_map_["slti"]   = 0x02;
    opcode_map_["sltiu"]  = 0x03;
    opcode_map_["xori"]   = 0x04;
    opcode_map_["ori"]    = 0x05;
    opcode_map_["andi"]   = 0x06;
    opcode_map_["slli"]   = 0x07;
    opcode_map_["srli"]   = 0x08;
    opcode_map_["srai"]   = 0x09;
    
    opcode_map_["add"]    = 0x10;
    opcode_map_["sub"]    = 0x11;
    opcode_map_["sll"]    = 0x12;
    opcode_map_["slt"]    = 0x13;
    opcode_map_["sltu"]   = 0x14;
    opcode_map_["xor"]    = 0x15;
    opcode_map_["srl"]    = 0x16;
    opcode_map_["sra"]    = 0x17;
    opcode_map_["or"]     = 0x18;
    opcode_map_["and"]    = 0x19;
    
    opcode_map_["mul"]    = 0x20;
    opcode_map_["mulh"]   = 0x21;
    opcode_map_["mulhsu"] = 0x22;
    opcode_map_["mulhu"]  = 0x23;
    opcode_map_["multiply"] = 0x20;
    
    opcode_map_["lw"]     = 0x24;
    opcode_map_["lh"]     = 0x25;
    opcode_map_["lhu"]    = 0x26;
    opcode_map_["lb"]     = 0x27;
    opcode_map_["lbu"]    = 0x28;
    opcode_map_["sw"]     = 0x29;
    opcode_map_["sh"]     = 0x2A;
    opcode_map_["sb"]     = 0x2B;
    
    opcode_map_["beq"]    = 0x30;
    opcode_map_["bne"]    = 0x31;
    opcode_map_["blt"]    = 0x32;
    opcode_map_["bge"]    = 0x33;
    opcode_map_["bltu"]   = 0x34;
    opcode_map_["bgeu"]   = 0x35;
    
    opcode_map_["jal"]    = 0x36;
    opcode_map_["jalr"]   = 0x37;
    
    opcode_map_["lui"]    = 0x38;
    opcode_map_["auipc"]  = 0x39;
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
// Output: opcode de 6 bits (0-63) o 0x00 si desconocido
uint8_t VLIWGenerator::getOpcode(const std::string& mnemonic) const {
    auto it = opcode_map_.find(mnemonic);
    if (it != opcode_map_.end()) {
        return it->second;
    }
    Logger::warning("Opcode desconocido: " + mnemonic + ", usando NOP");
    return 0x00;
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

// Retorna codificación de NOP (todos los bits en 0)
uint32_t VLIWGenerator::encodeNOP() const {
    return 0x00000000;
}

// Codifica una instrucción RISC-V a 32 bits según formato VLIW
// Input: sched_inst (instrucción planificada con ID, PE, ciclo)
// Output: palabra de 32 bits con opcode, registros e inmediato
uint32_t VLIWGenerator::encodeInstruction(const ScheduledInstruction& sched_inst) const {
    const auto& instructions = parser_.getInstructions();
    if (sched_inst.instruction_id >= static_cast<int>(instructions.size())) {
        Logger::error("ID de instrucción fuera de rango: " + std::to_string(sched_inst.instruction_id));
        return encodeNOP();
    }
    
    const Instruction& inst = instructions[sched_inst.instruction_id];
    
    uint32_t encoding = 0;
    
    uint8_t opcode = getOpcode(inst.getOpcode());
    encoding |= (static_cast<uint32_t>(opcode & 0x3F) << 26);
    
    if (!inst.isBranchOperation() && !inst.isStoreOperation()) {
        uint8_t rd = getRegisterNumber(inst.getRd());
        encoding |= (static_cast<uint32_t>(rd & 0x1F) << 21);
    }
    
    uint8_t rs1 = getRegisterNumber(inst.getRs1());
    encoding |= (static_cast<uint32_t>(rs1 & 0x1F) << 16);
    
    uint8_t rs2 = getRegisterNumber(inst.getRs2());
    encoding |= (static_cast<uint32_t>(rs2 & 0x1F) << 11);
    
    if (inst.hasImmediateValue()) {
        int16_t imm = static_cast<int16_t>(inst.getImmediate());
        encoding |= (static_cast<uint32_t>(imm & 0x7FF));
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

// Decodifica palabra de 32 bits a string assembly legible
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
    int16_t imm = extractImmediate(encoding);
    
    std::string mnemonic = "unknown";
    for (const auto& pair : opcode_map_) {
        if (pair.second == opcode) {
            mnemonic = pair.first;
            break;
        }
    }
    
    bool is_branch = (opcode >= 0x30 && opcode <= 0x35);
    bool is_store = (opcode >= 0x29 && opcode <= 0x2B);
    
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
    
    // B-Type: beq rs1, rs2, offset (NO rd)
    // S-Type: sw rs2, offset(rs1) (NO rd)
    if (is_branch) {
        oss << " rs1=" << rs1_name << " rs2=" << rs2_name;
        if (imm != 0) {
            oss << " offset=" << imm;
        }
    } else if (is_store) {
        oss << " rs2=" << rs2_name << " rs1=" << rs1_name;
        if (imm != 0) {
            oss << " offset=" << imm;
        }
    } else {
        // I, R, J, U types: tienen rd
        oss << " rd=" << rd_name << " rs1=" << rs1_name;
        
        // R-Type y algunas I-Type usan rs2
        if (rs2 != 0 || (opcode >= 0x10 && opcode <= 0x23)) {
            oss << " rs2=" << rs2_name;
        }
        
        // Mostrar inmediato si es relevante
        if (imm != 0 || (opcode >= 0x01 && opcode <= 0x09) || (opcode >= 0x24 && opcode <= 0x28)) {
            oss << " imm=" << imm;
        }
    }
    
    return oss.str();
}

uint8_t VLIWGenerator::extractOpcode(uint32_t encoding) const {
    return (encoding >> 26) & 0x3F;
}

uint8_t VLIWGenerator::extractRd(uint32_t encoding) const {
    return (encoding >> 21) & 0x1F;
}

uint8_t VLIWGenerator::extractRs1(uint32_t encoding) const {
    return (encoding >> 16) & 0x1F;
}

uint8_t VLIWGenerator::extractRs2(uint32_t encoding) const {
    return (encoding >> 11) & 0x1F;
}

int16_t VLIWGenerator::extractImmediate(uint32_t encoding) const {
    // Extraer 11 bits y extender signo
    uint16_t imm = encoding & 0x7FF;
    // Extender signo de 11 bits a 16 bits
    if (imm & 0x400) {  // Bit 10 es el signo
        imm |= 0xF800;  // Extender con 1s
    }
    return static_cast<int16_t>(imm);
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
    file << "# Each PE instruction: [Opcode(6):Rd(5):Rs1(5):Rs2(5):Imm(11)]\n";
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
    file << "# Each PE instruction: [Opcode(6):Rd(5):Rs1(5):Rs2(5):Imm(11)]\n";
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
    file << "  PE Encoding: 32 bits [Opcode(6):Rd(5):Rs1(5):Rs2(5):Imm(11)]\n";
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
    std::cout << "  PE Instruction Format: 32 bits\n";
    std::cout << "    [31:26] Opcode (6 bits)\n";
    std::cout << "    [25:21] Rd (5 bits)\n";
    std::cout << "    [20:16] Rs1 (5 bits)\n";
    std::cout << "    [15:11] Rs2 (5 bits)\n";
    std::cout << "    [10:0]  Immediate (11 bits)\n\n";
    
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
    file << "# Encoding: [Opcode(6):Rd(5):Rs1(5):Rs2(5):Imm(11)]\n";
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
