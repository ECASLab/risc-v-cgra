#ifndef VLIW_GENERATOR_H
#define VLIW_GENERATOR_H

#include <string>
#include <vector>
#include <cstdint>
#include <map>
#include "../scheduling/Scheduler.h"
#include "../parser/Parser.h"
#include "../config/ConfigReader.h"

// Palabra VLIW de 128 bits (4 PEs × 32 bits)
struct VLIWInstruction {
    uint32_t pe0_encoding, pe1_encoding, pe2_encoding, pe3_encoding;
    int cycle;
    VLIWInstruction() : pe0_encoding(0), pe1_encoding(0), pe2_encoding(0), pe3_encoding(0), cycle(0) {}
};

// Formato de 32 bits por PE según ISA estándar RISC-V:
// R-Type: [31:25]=funct7 [24:20]=rs2 [19:15]=rs1 [14:12]=funct3 [11:7]=rd [6:0]=opcode
// I-Type: [31:20]=imm[11:0] [19:15]=rs1 [14:12]=funct3 [11:7]=rd [6:0]=opcode
// S-Type: [31:25]=imm[11:5] [24:20]=rs2 [19:15]=rs1 [14:12]=funct3 [11:7]=imm[4:0] [6:0]=opcode
// B-Type: [31]=imm[12] [30:25]=imm[10:5] [24:20]=rs2 [19:15]=rs1 [14:12]=funct3 [11:8]=imm[4:1] [7]=imm[11] [6:0]=opcode
// U-Type: [31:12]=imm[31:12] [11:7]=rd [6:0]=opcode
// J-Type: [31]=imm[20] [30:21]=imm[10:1] [20]=imm[11] [19:12]=imm[19:12] [11:7]=rd [6:0]=opcode
// Genera código VLIW ejecutable a partir del schedule
class VLIWGenerator {
public:
    VLIWGenerator(const Scheduler& scheduler, 
                  const Parser& parser,
                  const ConfigReader& config);
    ~VLIWGenerator() = default;
    
    void generate();
    const std::vector<VLIWInstruction>& getVLIWInstructions() const { return vliw_instructions_; }
    
    void saveBinaryFile(const std::string& filename) const;
    void saveHexFileConcatenated(const std::string& filename) const;
    void saveHexFileSeparated(const std::string& filename) const;
    void saveVerilogMemFile(const std::string& filename) const;
    void saveDetailedFile(const std::string& filename) const;
    void saveAssemblyFile(const std::string& filename) const;
    void saveELFFile(const std::string& filename) const;
    void saveAllFormats(const std::string& output_dir, const std::string& base_name) const;
    void printStatistics() const;
    
private:
    const Scheduler& scheduler_;
    const Parser& parser_;
    const ConfigReader& config_;
    
    std::vector<VLIWInstruction> vliw_instructions_;
    std::map<std::string, uint8_t> opcode_map_;
    std::map<std::string, uint8_t> register_map_;
    
    void initializeOpcodeMappings();
    void initializeRegisterMappings();
    uint32_t encodeInstruction(const ScheduledInstruction& sched_inst) const;
    uint8_t getOpcode(const std::string& mnemonic) const;
    uint8_t getFunct3(const std::string& mnemonic) const;
    uint8_t getFunct7(const std::string& mnemonic) const;
    uint8_t getRegisterNumber(const std::string& reg_name) const;
    uint32_t encodeNOP() const;
    uint8_t extractOpcode(uint32_t encoding) const;
    uint8_t extractRd(uint32_t encoding) const;
    uint8_t extractRs1(uint32_t encoding) const;
    uint8_t extractRs2(uint32_t encoding) const;
    int16_t extractImmediate(uint32_t encoding) const;
    std::string decodeToString(uint32_t encoding) const;
    
    struct Statistics {
        int total_vliw_words;
        int total_operations;
        int nop_count;
        double utilization;
        std::map<std::string, int> operation_histogram;
    };
    Statistics calculateStatistics() const;
};

#endif // VLIW_GENERATOR_H
