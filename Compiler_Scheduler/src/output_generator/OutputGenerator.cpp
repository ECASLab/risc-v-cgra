#include "OutputGenerator.h"
#include "../utils/Logger.h"
#include "../register_init/RegisterInitializer.h"
#include <fstream>
#include <iomanip>
#include <map>
#include <algorithm>

// Constructor: inicializa generador con referencias a scheduler, mapper, parser y config
// Input: scheduler (planificador), mapper (mapeador PE), parser (analizador), config (configuración)
// Output: instancia de OutputGenerator
OutputGenerator::OutputGenerator(const Scheduler& scheduler,
                                const PEMapper& mapper,
                                const Parser& parser,
                                const ConfigReader& config)
    : scheduler_(scheduler), mapper_(mapper), parser_(parser), config_(config) {
}

// Genera todos los archivos de salida (schedule, métricas, visualización, etc.)
// Input: output_dir (directorio de salida)
// Output: múltiples archivos de texto con resultados
void OutputGenerator::generateAll(const std::string& output_dir) {
    Logger::info("Generando archivos de salida...");
    
    generateScheduleFile(output_dir + "/phase3_schedule.txt");
    generateHardwareConfig(output_dir + "/phase3_hardware.txt");
    generateMetricsFile(output_dir + "/phase3_metrics.txt");
    generateVisualization(output_dir + "/phase3_visualization.txt");
    generateArbiterStats(output_dir + "/phase3_arbiter_stats.txt");
    generateCombinedOutput(output_dir + "/phase3_combined.txt");
    generateInitializedAssembly(output_dir + "/phase3_initialized_code.s");
    
    Logger::info("Archivos de salida generados en: " + output_dir);
}

// Genera archivo con el schedule detallado (ciclo, PE, instrucción, latencia)
// Input: filename (ruta del archivo)
// Output: archivo de texto con schedule en formato tabla
void OutputGenerator::generateScheduleFile(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return;
    }
    
    const auto& schedule = scheduler_.getSchedule();
    
    file << "# CGRA Schedule Output\n";
    file << "# Total Instructions: " << schedule.size() << "\n";
    file << "# Makespan: " << scheduler_.getMakespan() << " cycles\n";
    file << "# Number of PEs: " << config_.getNumPEs() << "\n\n";
    
    file << "# Format: CYCLE | PE | INST_ID | OPCODE | RD | RS1 | RS2 | IMM | LATENCY | BUS | CRITICAL\n";
    file << "# ---------------------------------------------------------------------------------------\n\n";
    
    std::map<int, std::vector<ScheduledInstruction>> by_cycle;
    for (const auto& si : schedule) {
        by_cycle[si.cycle].push_back(si);
    }
    
    for (const auto& [cycle, insts] : by_cycle) {
        for (const auto& si : insts) {
            file << std::setw(5) << cycle << " | "
                 << std::setw(2) << si.pe_id << " | "
                 << std::setw(7) << si.instruction_id << " | "
                 << std::setw(10) << std::left << si.opcode << " | "
                 << std::setw(5) << (si.rd.empty() ? "-" : si.rd) << " | "
                 << std::setw(5) << (si.rs1.empty() ? "-" : si.rs1) << " | "
                 << std::setw(5) << (si.rs2.empty() ? "-" : si.rs2) << " | "
                 << std::setw(6) << (si.imm.empty() ? "-" : si.imm) << " | "
                 << std::setw(7) << si.latency << " | "
                 << std::setw(3) << (si.requires_bus ? "YES" : "NO") << " | "
                 << (si.is_critical ? "CRIT" : "-") << "\n";
        }
    }
    
    file.close();
}

// Genera archivo con la configuración de hardware usada (PEs, registros, particionado)
// Input: filename (ruta del archivo)
// Output: archivo de texto con configuración de hardware
void OutputGenerator::generateHardwareConfig(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return;
    }
    
    file << "# Hardware Configuration Used\n\n";
    
    file << "=== CGRA Configuration ===\n";
    file << "Number of PEs: " << config_.getNumPEs() << "\n";
    file << "Registers per PE: " << config_.getNumRegisters() / config_.getNumPEs() << "\n";
    file << "Total Registers: " << config_.getNumRegisters() << "\n";
    file << "Memory Banks: " << config_.getMemoryBanks() << "\n\n";
    
    file << "=== Register Partitioning ===\n";
    int regs_per_pe = config_.getNumRegisters() / config_.getNumPEs();
    for (int pe = 0; pe < config_.getNumPEs(); pe++) {
        int start = pe * regs_per_pe;
        int end = (pe + 1) * regs_per_pe - 1;
        if (pe == config_.getNumPEs() - 1) {
            end = config_.getNumRegisters() - 1;
        }
        file << "PE" << pe << ": x" << start << " - x" << end << "\n";
    }
    
    file.close();
}

// Genera archivo con métricas de performance (IPC, utilización, speedup, eficiencia)
// Input: filename (ruta del archivo)
// Output: archivo de texto con métricas detalladas
void OutputGenerator::generateMetricsFile(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return;
    }
    
    file << "# Performance Metrics\n\n";
    
    file << "=== Execution Metrics ===\n";
    file << "Total Instructions: " << parser_.getInstructions().size() << "\n";
    file << "Scheduled Instructions: " << scheduler_.getSchedule().size() << "\n";
    file << "Makespan (cycles): " << scheduler_.getMakespan() << "\n";
    file << "IPC (Instructions Per Cycle): " << std::fixed << std::setprecision(4) 
         << mapper_.getIPC() << "\n\n";
    
    file << "=== Resource Utilization ===\n";
    file << "Number of PEs: " << config_.getNumPEs() << "\n";
    file << "Overall PE Utilization: " << std::fixed << std::setprecision(2) 
         << mapper_.getOverallUtilization() << "%\n\n";
    
    file << "=== Per-PE Utilization ===\n";
    for (const auto& stat : mapper_.getStatistics()) {
        file << "PE" << stat.pe_id << ": " 
             << std::setw(6) << std::fixed << std::setprecision(2) 
             << stat.utilization << "% "
             << "(" << stat.instructions_executed << " instructions)\n";
    }
    file << "\n";
    
    file << "=== Performance Analysis ===\n";
    double speedup = calculateSpeedup();
    double efficiency = calculateEfficiency();
    
    file << "Theoretical Speedup: " << std::fixed << std::setprecision(2) 
         << speedup << "x\n";
    file << "Parallel Efficiency: " << std::fixed << std::setprecision(2) 
         << efficiency << "%\n";
    
    // Calcular tiempo secuencial estimado
    int sequential_time = 0;
    for (const auto& si : scheduler_.getSchedule()) {
        sequential_time += si.latency;
    }
    file << "Sequential Execution Time (est.): " << sequential_time << " cycles\n";
    file << "Parallel Execution Time: " << scheduler_.getMakespan() << " cycles\n";
    file << "Time Saved: " << (sequential_time - scheduler_.getMakespan()) 
         << " cycles (" 
         << std::fixed << std::setprecision(1) 
         << (double)(sequential_time - scheduler_.getMakespan()) / sequential_time * 100.0 
         << "%)\n";
    
    file.close();
}

// Genera visualización del schedule en formato Gantt (texto)
// Input: filename (ruta del archivo)
// Output: archivo de texto con diagrama Gantt del schedule
void OutputGenerator::generateVisualization(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return;
    }
    
    const auto& schedule = scheduler_.getSchedule();
    int makespan = scheduler_.getMakespan();
    int num_pes = config_.getNumPEs();
    
    file << "# Schedule Visualization (Gantt Chart - Text Format)\n\n";
    
    std::vector<std::vector<std::string>> gantt(num_pes);
    for (int pe = 0; pe < num_pes; pe++) {
        gantt[pe].resize(makespan, "  .  ");
    }
    
    for (const auto& si : schedule) {
        std::string label = "I" + std::to_string(si.instruction_id);
        if (label.length() > 5) label = label.substr(0, 5);
        while (label.length() < 5) label = " " + label;
        
        for (int c = si.cycle; c < si.cycle + si.latency && c < makespan; c++) {
            gantt[si.pe_id][c] = label;
        }
    }
    
    file << "Cycle: ";
    for (int c = 0; c < std::min(makespan, 80); c++) {
        file << std::setw(5) << c;
    }
    file << "\n";
    file << std::string(6 + std::min(makespan, 80) * 5, '-') << "\n";
    
    for (int pe = 0; pe < num_pes; pe++) {
        file << "PE" << pe << " | ";
        for (int c = 0; c < std::min(makespan, 80); c++) {
            file << gantt[pe][c];
        }
        file << "\n";
    }
    
    if (makespan > 80) {
        file << "\n(Mostrando solo los primeros 80 ciclos de " << makespan << ")\n";
    }
    
    file << "\n\nLegend:\n";
    file << "  .   = Idle\n";
    file << "  IN  = Instruction N executing\n";
    
    file.close();
}

// Genera archivo combinado con resumen de todas las métricas y estadísticas
// Input: filename (ruta del archivo)
// Output: archivo de texto con resumen ejecutivo completo
void OutputGenerator::generateCombinedOutput(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return;
    }
    
    file << "╔════════════════════════════════════════════════════════════════╗\n";
    file << "║          CGRA COMPILER - PHASE 3 COMBINED OUTPUT              ║\n";
    file << "╚════════════════════════════════════════════════════════════════╝\n\n";
    
    file << "═══════════════════════════════════════════════════════════════\n";
    file << "  COMPILATION SUMMARY\n";
    file << "═══════════════════════════════════════════════════════════════\n\n";
    
    file << "Total Instructions Parsed: " << parser_.getInstructions().size() << "\n";
    file << "Instructions Scheduled: " << scheduler_.getSchedule().size() << "\n";
    file << "Target Hardware: " << config_.getNumPEs() << " PEs, " 
         << config_.getNumRegisters() << " registers\n\n";
    
    file << "═══════════════════════════════════════════════════════════════\n";
    file << "  PERFORMANCE METRICS\n";
    file << "═══════════════════════════════════════════════════════════════\n\n";
    
    file << "Makespan: " << scheduler_.getMakespan() << " cycles\n";
    file << "IPC: " << std::fixed << std::setprecision(4) << mapper_.getIPC() << "\n";
    file << "PE Utilization: " << std::fixed << std::setprecision(2) 
         << mapper_.getOverallUtilization() << "%\n";
    file << "Speedup: " << std::fixed << std::setprecision(2) 
         << calculateSpeedup() << "x\n";
    file << "Efficiency: " << std::fixed << std::setprecision(2) 
         << calculateEfficiency() << "%\n\n";
    
    file << "═══════════════════════════════════════════════════════════════\n";
    file << "  PE STATISTICS\n";
    file << "═══════════════════════════════════════════════════════════════\n\n";
    
    for (const auto& stat : mapper_.getStatistics()) {
        file << "PE" << stat.pe_id << ": "
             << stat.instructions_executed << " instructions, "
             << std::fixed << std::setprecision(1) << stat.utilization << "% utilized\n";
    }
    
    file << "\n═══════════════════════════════════════════════════════════════\n";
    file << "  For detailed information, see individual phase3_*.txt files\n";
    file << "═══════════════════════════════════════════════════════════════\n";
    
    file.close();
}

// Calcula el speedup teórico comparando tiempo secuencial vs paralelo
// Input: ninguno (usa scheduler_ interno)
// Output: valor de speedup (tiempo_secuencial / makespan)
double OutputGenerator::calculateSpeedup() const {
    int sequential_time = 0;
    for (const auto& si : scheduler_.getSchedule()) {
        sequential_time += si.latency;
    }
    
    if (scheduler_.getMakespan() == 0) return 0.0;
    return (double)sequential_time / scheduler_.getMakespan();
}

// Calcula la eficiencia como porcentaje del speedup ideal
// Input: ninguno (usa scheduler_ y config_ interno)
// Output: eficiencia en porcentaje (speedup / num_pes * 100)
double OutputGenerator::calculateEfficiency() const {
    double speedup = calculateSpeedup();
    if (config_.getNumPEs() == 0) return 0.0;
    return (speedup / config_.getNumPEs()) * 100.0;
}

// Genera archivo con estadísticas del arbiter (accesos, contenciones, uso del bus)
// Input: filename (ruta del archivo)
// Output: archivo de texto con análisis del arbiter
void OutputGenerator::generateArbiterStats(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return;
    }
    
    const Arbiter& arbiter = scheduler_.getArbiter();
    
    file << "╔════════════════════════════════════════════════════════════════╗\n";
    file << "║              BUS ARBITER STATISTICS                            ║\n";
    file << "╚════════════════════════════════════════════════════════════════╝\n\n";
    
    file << "=== ARBITER CONFIGURATION ===\n";
    file << "Policy: " << config_.getArbiterPolicy() << "\n";
    file << "Grant Latency: " << config_.getArbiterGrantLatency() << " cycle(s)\n";
    file << "Contention Penalty: " << config_.getArbiterContentionPenalty() << " cycle(s)\n";
    file << "Number of PEs: " << config_.getNumPEs() << "\n\n";
    
    file << "=== BUS USAGE STATISTICS ===\n";
    file << "Total Bus Accesses: " << arbiter.getTotalBusAccesses() << "\n";
    file << "Total Contentions: " << arbiter.getTotalContentions() << "\n";
    file << "Bus Utilization: " << std::fixed << std::setprecision(2) 
         << arbiter.getBusUtilization() << "%\n";
    file << "Makespan: " << scheduler_.getMakespan() << " cycles\n\n";
    
    int total_accesses = arbiter.getTotalBusAccesses();
    int total_contentions = arbiter.getTotalContentions();
    double contention_rate = (total_accesses > 0) ? 
        (double)total_contentions / total_accesses * 100.0 : 0.0;
    
    file << "Contention Rate: " << std::fixed << std::setprecision(2) 
         << contention_rate << "%\n";
    file << "Average Requests per Access: " << std::fixed << std::setprecision(2)
         << (total_contentions > 0 ? (double)(total_contentions + total_accesses) / total_accesses : 1.0)
         << "\n\n";
    
    file << "=== PER-PE BUS USAGE ===\n";
    file << std::setw(5) << "PE" << " | "
         << std::setw(12) << "Accesses" << " | "
         << std::setw(12) << "Contentions" << " | "
         << std::setw(10) << "Usage %\n";
    file << std::string(46, '-') << "\n";
    
    auto bus_usage = arbiter.getBusUsageStats();
    auto contentions = arbiter.getContentionsByPE();
    
    for (int pe = 0; pe < config_.getNumPEs(); pe++) {
        int accesses = (bus_usage.find(pe) != bus_usage.end()) ? bus_usage.at(pe) : 0;
        int pe_contentions = (contentions.find(pe) != contentions.end()) ? contentions.at(pe) : 0;
        double usage_pct = (total_accesses > 0) ? (double)accesses / total_accesses * 100.0 : 0.0;
        
        file << std::setw(5) << pe << " | "
             << std::setw(12) << accesses << " | "
             << std::setw(12) << pe_contentions << " | "
             << std::setw(9) << std::fixed << std::setprecision(2) << usage_pct << "%\n";
    }
    
    file << "\n=== ANALYSIS ===\n";
    if (contention_rate < 10.0) {
        file << "✓ LOW contention: Bus arbitration is efficient.\n";
    } else if (contention_rate < 30.0) {
        file << "⚠ MODERATE contention: Consider load balancing optimizations.\n";
    } else {
        file << "✗ HIGH contention: Significant bus bottleneck detected.\n";
        file << "  Recommendations:\n";
        file << "  - Improve instruction locality\n";
        file << "  - Reduce inter-PE communication\n";
        file << "  - Consider partitioning strategies\n";
    }
    
    if (arbiter.getBusUtilization() > 80.0) {
        file << "⚠ Bus heavily utilized (>80%). May be a bottleneck.\n";
    } else if (arbiter.getBusUtilization() < 20.0) {
        file << "ℹ Bus underutilized (<20%). Most operations are PE-local.\n";
    }
    
    file << "\n=== DETAILED GRANT HISTORY ===\n";
    file << "Note: See phase3_schedule.txt for instruction-level bus access patterns.\n";
    
    file.close();
    Logger::info("Arbiter statistics saved to: " + filename);
}

// Genera archivo assembly con bloque de inicialización de registros
// Input: filename (ruta del archivo)
// Output: archivo .s con bloque de inicialización + código original
void OutputGenerator::generateInitializedAssembly(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return;
    }
    
    Logger::info("Generando código assembly con inicialización de registros...");
    
    // Crear inicializador y recopilar registros usados
    RegisterInitializer initializer(parser_);
    initializer.collectUsedRegisters();
    
    file << "# ╔══════════════════════════════════════════════════════════════════╗\n";
    file << "# ║    CÓDIGO ASSEMBLY CON INICIALIZACIÓN DE REGISTROS              ║\n";
    file << "# ║    Generado por CGRA Compiler - Phase 3                         ║\n";
    file << "# ╚══════════════════════════════════════════════════════════════════╝\n";
    file << "#\n";
    file << "# Registros únicos detectados: " << initializer.getUsedRegisters().size() << "\n";
    file << "# Instrucciones originales: " << parser_.getInstructions().size() << "\n";
    file << "#\n\n";
    
    // Generar bloque de inicialización
    auto init_block = initializer.generateInitBlock();
    for (const auto& line : init_block) {
        file << line << "\n";
    }
    
    // Agregar código original
    file << "\n";
    file << "# ============================================\n";
    file << "# CÓDIGO ORIGINAL\n";
    file << "# ============================================\n";
    file << "\n";
    
    const auto& instructions = parser_.getInstructions();
    const auto& labels = parser_.getLabels();
    
    // Crear mapa inverso de labels (índice -> nombre)
    std::map<int, std::string> label_by_index;
    for (const auto& [label_name, index] : labels) {
        label_by_index[index] = label_name;
    }
    
    // Escribir instrucciones con labels
    for (size_t i = 0; i < instructions.size(); i++) {
        // Si hay un label en este índice, escribirlo primero
        if (label_by_index.find(i) != label_by_index.end()) {
            file << label_by_index[i] << ":\n";
        }
        
        // Escribir instrucción
        const auto& instr = instructions[i];
        file << "    " << instr.getOpcode();
        
        // Reconstruir operandos según el tipo de instrucción
        if (instr.isStoreOperation()) {
            // Store: sw rs2, offset(rs1)
            if (!instr.getRs2().empty()) {
                file << " " << instr.getRs2();
                if (!instr.getRs1().empty()) {
                    file << ", " << instr.getImmediate() << "(" << instr.getRs1() << ")";
                }
            }
        } else if (instr.isLoadOperation()) {
            // Load: lw rd, offset(rs1)
            if (!instr.getRd().empty()) {
                file << " " << instr.getRd();
                if (!instr.getRs1().empty()) {
                    file << ", " << instr.getImmediate() << "(" << instr.getRs1() << ")";
                }
            }
        } else if (instr.isBranchOperation()) {
            // Branch: beq rs1, rs2, label
            if (!instr.getRs1().empty()) {
                file << " " << instr.getRs1();
                if (!instr.getRs2().empty()) {
                    file << ", " << instr.getRs2();
                }
                if (!instr.getLabel().empty()) {
                    file << ", " << instr.getLabel();
                }
            }
        } else if (instr.isJumpOperation()) {
            // Jump: jal rd, label OR jal label
            if (!instr.getRd().empty() && instr.getRd() != "x1") {
                file << " " << instr.getRd();
                if (!instr.getLabel().empty()) {
                    file << ", " << instr.getLabel();
                }
            } else if (!instr.getLabel().empty()) {
                file << " " << instr.getLabel();
            }
        } else if (instr.getType() == InstructionType::R_TYPE) {
            // R-Type: add rd, rs1, rs2
            if (!instr.getRd().empty()) {
                file << " " << instr.getRd();
                if (!instr.getRs1().empty()) {
                    file << ", " << instr.getRs1();
                    if (!instr.getRs2().empty()) {
                        file << ", " << instr.getRs2();
                    }
                }
            }
        } else if (instr.getType() == InstructionType::I_TYPE && !instr.isLoadOperation()) {
            // I-Type (ALU): addi rd, rs1, imm
            if (!instr.getRd().empty()) {
                file << " " << instr.getRd();
                if (!instr.getRs1().empty()) {
                    file << ", " << instr.getRs1();
                    if (instr.hasImmediateValue()) {
                        file << ", " << instr.getImmediate();
                    }
                }
            }
        } else if (instr.getType() == InstructionType::U_TYPE) {
            // U-Type: lui rd, imm
            if (!instr.getRd().empty()) {
                file << " " << instr.getRd();
                if (instr.hasImmediateValue()) {
                    file << ", " << instr.getImmediate();
                }
            }
        }
        
        file << "\n";
    }
    
    file << "\n# ============================================\n";
    file << "# FIN DEL CÓDIGO\n";
    file << "# ============================================\n";
    
    file.close();
    Logger::info("Código assembly con inicialización guardado en: " + filename);
    
    // También guardar reporte de registros
    std::string report_file = filename.substr(0, filename.rfind('/')) + "/phase3_register_init_report.txt";
    initializer.saveToFile(report_file);
}
