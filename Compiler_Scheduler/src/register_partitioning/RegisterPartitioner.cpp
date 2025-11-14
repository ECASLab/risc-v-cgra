#include "RegisterPartitioner.h"
#include "../utils/Logger.h"
#include <fstream>
#include <algorithm>

// Constructor: inicializa particionador con configuración de PEs y registros
// Input: config (configuración del hardware)
// Output: instancia de RegisterPartitioner
RegisterPartitioner::RegisterPartitioner(const ConfigReader& config)
    : num_pes_(config.getNumPEs()), num_registers_(config.getNumRegisters()) {
}

// Crea las particiones de registros dividiendo equitativamente entre PEs
// Input: ninguno (usa num_pes_ y num_registers_ internos)
// Output: vector de particiones con rangos de registros asignados a cada PE
void RegisterPartitioner::createPartitions() {
    Logger::info("Creando particionamiento de registros...");
    
    partitions_.clear();
    register_to_pe_.clear();
    
    int regs_per_pe = num_registers_ / num_pes_;
    
    for (int pe = 0; pe < num_pes_; pe++) {
        RegisterPartition partition;
        partition.pe_id = pe;
        partition.start_reg = pe * regs_per_pe;
        partition.end_reg = (pe + 1) * regs_per_pe - 1;
        
        if (pe == num_pes_ - 1) {
            partition.end_reg = num_registers_ - 1;
        }
        
        for (int r = partition.start_reg; r <= partition.end_reg; r++) {
            std::string reg_name = "x" + std::to_string(r);
            partition.registers.insert(reg_name);
            register_to_pe_[reg_name] = pe;
            
            // También mapear nombres alternativos (ABI names)
            if (r == 0) { register_to_pe_["zero"] = pe; partition.registers.insert("zero"); }
            else if (r == 1) { register_to_pe_["ra"] = pe; partition.registers.insert("ra"); }
            else if (r == 2) { register_to_pe_["sp"] = pe; partition.registers.insert("sp"); }
            else if (r == 3) { register_to_pe_["gp"] = pe; partition.registers.insert("gp"); }
            else if (r == 4) { register_to_pe_["tp"] = pe; partition.registers.insert("tp"); }
            else if (r >= 5 && r <= 7) { 
                std::string t = "t" + std::to_string(r - 5);
                register_to_pe_[t] = pe; 
                partition.registers.insert(t);
            }
            else if (r == 8) { register_to_pe_["s0"] = pe; partition.registers.insert("s0"); register_to_pe_["fp"] = pe; }
            else if (r == 9) { register_to_pe_["s1"] = pe; partition.registers.insert("s1"); }
            else if (r >= 10 && r <= 17) {
                std::string a = "a" + std::to_string(r - 10);
                register_to_pe_[a] = pe;
                partition.registers.insert(a);
            }
            else if (r >= 18 && r <= 27) {
                std::string s = "s" + std::to_string(r - 16);
                register_to_pe_[s] = pe;
                partition.registers.insert(s);
            }
            else if (r >= 28 && r <= 31) {
                std::string t = "t" + std::to_string(r - 25);
                register_to_pe_[t] = pe;
                partition.registers.insert(t);
            }
        }
        
        partitions_.push_back(partition);
    }
    
    Logger::info("Particionamiento creado: " + std::to_string(num_pes_) + " PEs, " + 
                 std::to_string(regs_per_pe) + " registros por PE");
}

// Obtiene el PE dueño de un registro dado
// Input: reg (nombre del registro, ej: "x5", "a0", "sp")
// Output: ID del PE propietario (0 a num_pes-1)
int RegisterPartitioner::getRegisterOwner(const std::string& reg) const {
    auto it = register_to_pe_.find(reg);
    if (it != register_to_pe_.end()) {
        return it->second;
    }
    
    int reg_num = getRegisterNumber(reg);
    if (reg_num >= 0 && reg_num < num_registers_) {
        int regs_per_pe = num_registers_ / num_pes_;
        return std::min(reg_num / regs_per_pe, num_pes_ - 1);
    }
    
    Logger::warning("Registro desconocido: " + reg + ", asignando a PE0");
    return 0;
}

// Verifica si una instrucción usa registros de múltiples PEs
// Input: inst (instrucción a verificar)
// Output: true si requiere más de un PE, false si no
bool RegisterPartitioner::hasCrossPEDependency(const Instruction& inst) const {
    std::set<int> pes = getRequiredPEs(inst);
    return pes.size() > 1;
}

// Obtiene el conjunto de PEs requeridos por una instrucción (rd, rs1, rs2)
// Input: inst (instrucción a analizar)
// Output: set de IDs de PEs necesarios
std::set<int> RegisterPartitioner::getRequiredPEs(const Instruction& inst) const {
    std::set<int> pes;
    
    std::string rd = inst.getRd();
    if (!rd.empty() && rd != "-") {
        pes.insert(getRegisterOwner(rd));
    }
    
    std::string rs1 = inst.getRs1();
    if (!rs1.empty() && rs1 != "-") {
        pes.insert(getRegisterOwner(rs1));
    }
    
    std::string rs2 = inst.getRs2();
    if (!rs2.empty() && rs2 != "-") {
        pes.insert(getRegisterOwner(rs2));
    }
    
    return pes;
}

// Convierte nombre de registro (xN o ABI name) a número
// Input: reg (nombre del registro)
// Output: número de registro (0-31) o -1 si inválido
int RegisterPartitioner::getRegisterNumber(const std::string& reg) const {
    if (reg.empty() || reg == "-") return -1;
    
    if (reg[0] == 'x') {
        try {
            return std::stoi(reg.substr(1));
        } catch (...) {
            return -1;
        }
    }
    
    if (reg == "zero") return 0;
    if (reg == "ra") return 1;
    if (reg == "sp") return 2;
    if (reg == "gp") return 3;
    if (reg == "tp") return 4;
    if (reg[0] == 't' && reg.length() == 2) {
        int n = reg[1] - '0';
        if (n >= 0 && n <= 2) return 5 + n;
        if (n >= 3 && n <= 6) return 28 + (n - 3);
    }
    if (reg == "s0" || reg == "fp") return 8;
    if (reg == "s1") return 9;
    if (reg[0] == 's' && reg.length() == 2) {
        int n = reg[1] - '0';
        if (n >= 2 && n <= 9) return 18 + (n - 2);
    }
    if (reg[0] == 'a' && reg.length() == 2) {
        int n = reg[1] - '0';
        if (n >= 0 && n <= 7) return 10 + n;
    }
    
    return -1;
}

// Imprime el particionamiento de registros a consola
void RegisterPartitioner::printPartitioning() const {
    Logger::info("\n=== PARTICIONAMIENTO DE REGISTROS ===");
    for (const auto& part : partitions_) {
        int num_regs = part.end_reg - part.start_reg + 1;
        Logger::info("\nPE" + std::to_string(part.pe_id) + ":");
        Logger::info("  Rango: x" + std::to_string(part.start_reg) + " - x" + std::to_string(part.end_reg));
        Logger::info("  Total: " + std::to_string(num_regs) + " registros");
    }
}

// Guarda el particionamiento en archivo de texto
// Input: filename (ruta del archivo)
// Output: archivo con rangos de registros por PE
void RegisterPartitioner::saveToFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo abrir archivo: " + filename);
        return;
    }
    
    file << "# Register Partitioning\n";
    file << "# Total PEs: " << num_pes_ << "\n";
    file << "# Total Registers: " << num_registers_ << "\n\n";
    
    for (const auto& part : partitions_) {
        int num_regs = part.end_reg - part.start_reg + 1;
        file << "=== PE" << part.pe_id << " ===\n";
        file << "Range: x" << part.start_reg << " - x" << part.end_reg << "\n";
        file << "Total: " << num_regs << " registers\n";
        file << "Aliases: ";
        
        bool first = true;
        for (const auto& reg : part.registers) {
            if (reg[0] != 'x') {  // Solo mostrar aliases, no xN
                if (!first) file << ", ";
                file << reg;
                first = false;
            }
        }
        file << "\n\n";
    }
    
    file.close();
    Logger::info("Particionamiento guardado en: " + filename);
}
