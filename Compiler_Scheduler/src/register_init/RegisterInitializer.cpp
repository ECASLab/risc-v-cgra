#include "RegisterInitializer.h"
#include "../utils/Logger.h"
#include <fstream>
#include <algorithm>

// Constructor: inicializa con referencia al parser
// Input: parser (analizador de código)
// Output: instancia de RegisterInitializer
RegisterInitializer::RegisterInitializer(const Parser& parser)
    : parser_(parser) {
}

// Analiza todas las instrucciones y recopila registros usados
// Input: ninguno (usa parser interno)
// Output: llena used_registers_ con todos los registros referenciados
void RegisterInitializer::collectUsedRegisters() {
    Logger::info("Recopilando registros usados...");
    
    used_registers_.clear();
    const auto& instructions = parser_.getInstructions();
    
    for (const auto& instr : instructions) {
        // Recopilar registros fuente (rs1, rs2)
        if (!instr.getRs1().empty() && shouldInitialize(instr.getRs1())) {
            used_registers_.insert(instr.getRs1());
        }
        
        if (!instr.getRs2().empty() && shouldInitialize(instr.getRs2())) {
            used_registers_.insert(instr.getRs2());
        }
        
        // Recopilar registro destino (rd)
        if (!instr.getRd().empty() && shouldInitialize(instr.getRd())) {
            used_registers_.insert(instr.getRd());
        }
    }
    
    Logger::info("Registros únicos detectados: " + std::to_string(used_registers_.size()));
}

// Verifica si un registro debe ser inicializado
// Input: reg (nombre del registro)
// Output: true si debe inicializarse, false si es especial (zero, sp)
bool RegisterInitializer::shouldInitialize(const std::string& reg) const {
    // No inicializar registros especiales
    if (reg == "zero" || reg == "x0") return false;
    if (reg == "sp" || reg == "x2") return false;
    if (reg.empty()) return false;
    
    return true;
}

// Genera bloque de inicialización con instrucciones addi rx, zero, 0
// Input: ninguno (usa used_registers_ interno)
// Output: vector de strings con instrucciones de inicialización
std::vector<std::string> RegisterInitializer::generateInitBlock() const {
    std::vector<std::string> init_block;
    
    init_block.push_back("# ============================================");
    init_block.push_back("# BLOQUE DE INICIALIZACIÓN DE REGISTROS");
    init_block.push_back("# Inicializa todos los registros usados a 0");
    init_block.push_back("# para evitar valores indefinidos (X)");
    init_block.push_back("# ============================================");
    init_block.push_back("");
    
    // Ordenar registros para salida consistente
    std::vector<std::string> sorted_regs(used_registers_.begin(), used_registers_.end());
    std::sort(sorted_regs.begin(), sorted_regs.end(), [](const std::string& a, const std::string& b) {
        // Ordenar por número de registro si es formato xN
        if (a.length() > 1 && a[0] == 'x' && b.length() > 1 && b[0] == 'x') {
            int num_a = std::stoi(a.substr(1));
            int num_b = std::stoi(b.substr(1));
            return num_a < num_b;
        }
        return a < b;
    });
    
    // Generar instrucciones de inicialización
    for (const auto& reg : sorted_regs) {
        std::string init_instr = "    addi " + reg + ", zero, 0";
        init_block.push_back(init_instr);
    }
    
    init_block.push_back("");
    init_block.push_back("# ============================================");
    init_block.push_back("# FIN BLOQUE DE INICIALIZACIÓN");
    init_block.push_back("# ============================================");
    init_block.push_back("");
    
    Logger::info("Bloque de inicialización generado con " + 
                 std::to_string(sorted_regs.size()) + " registros");
    
    return init_block;
}

// Guarda información de inicialización a archivo
// Input: filename (ruta del archivo)
// Output: true si guardado exitoso, false si falla
bool RegisterInitializer::saveToFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return false;
    }
    
    file << "# Análisis de Registros Usados\n";
    file << "# Total de registros únicos: " << used_registers_.size() << "\n\n";
    
    file << "=== Registros Detectados ===\n";
    
    std::vector<std::string> sorted_regs(used_registers_.begin(), used_registers_.end());
    std::sort(sorted_regs.begin(), sorted_regs.end(), [](const std::string& a, const std::string& b) {
        if (a.length() > 1 && a[0] == 'x' && b.length() > 1 && b[0] == 'x') {
            int num_a = std::stoi(a.substr(1));
            int num_b = std::stoi(b.substr(1));
            return num_a < num_b;
        }
        return a < b;
    });
    
    for (const auto& reg : sorted_regs) {
        file << "  " << reg << "\n";
    }
    
    file << "\n=== Bloque de Inicialización Generado ===\n\n";
    
    auto init_block = generateInitBlock();
    for (const auto& line : init_block) {
        file << line << "\n";
    }
    
    file.close();
    Logger::info("Información de inicialización guardada en: " + filename);
    return true;
}
