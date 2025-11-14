#include "PEMapper.h"
#include "../utils/Logger.h"
#include <fstream>
#include <algorithm>
#include <iomanip>

// Constructor
// Input: scheduler con asignaciones, configuracion de hardware
PEMapper::PEMapper(const Scheduler& scheduler, const ConfigReader& config)
    : scheduler_(scheduler), config_(config),
      makespan_(scheduler.getMakespan()),
      num_pes_(config.getNumPEs()),
      total_instructions_(scheduler.getSchedule().size()) {
    
    statistics_.resize(num_pes_);
    for (int i = 0; i < num_pes_; i++) {
        statistics_[i].pe_id = i;
        statistics_[i].instructions_executed = 0;
        statistics_[i].total_cycles = makespan_;
        statistics_[i].idle_cycles = makespan_;
        statistics_[i].utilization = 0.0;
    }
}

// Analiza el mapeo de instrucciones a PEs y calcula estadisticas
void PEMapper::analyzeMapping() {
    Logger::info("Analizando mapeo de instrucciones a PEs...");
    
    const auto& schedule = scheduler_.getSchedule();
    std::map<int, std::set<int>> pe_busy_cycles;
    
    for (const auto& si : schedule) {
        int pe = si.pe_id;
        
        statistics_[pe].instructions_executed++;
        statistics_[pe].instruction_ids.push_back(si.instruction_id);
        
        for (int c = si.cycle; c < si.cycle + si.latency; c++) {
            pe_busy_cycles[pe].insert(c);
        }
    }
    
    for (int pe = 0; pe < num_pes_; pe++) {
        int busy_cycles = pe_busy_cycles[pe].size();
        statistics_[pe].idle_cycles = makespan_ - busy_cycles;
        
        if (makespan_ > 0) {
            statistics_[pe].utilization = 
                (double)busy_cycles / makespan_ * 100.0;
        }
    }
    
    Logger::info("Análisis de mapeo completado");
}

// Calcula la utilizacion total del array de PEs
// Output: porcentaje de utilizacion (0-100)
double PEMapper::getOverallUtilization() const {
    if (num_pes_ == 0 || makespan_ == 0) return 0.0;
    
    int total_busy_cycles = 0;
    for (const auto& stat : statistics_) {
        total_busy_cycles += (stat.total_cycles - stat.idle_cycles);
    }
    
    int total_available_cycles = num_pes_ * makespan_;
    return (double)total_busy_cycles / total_available_cycles * 100.0;
}

// Calcula instrucciones por ciclo (IPC)
// Output: valor de IPC
double PEMapper::getIPC() const {
    if (makespan_ == 0) return 0.0;
    return (double)total_instructions_ / makespan_;
}

// Imprime estadisticas de mapeo en consola
void PEMapper::printMapping() const {
    Logger::info("\n=== MAPEO Y ESTADÍSTICAS DE PEs ===");
    
    for (const auto& stat : statistics_) {
        Logger::info("\nPE" + std::to_string(stat.pe_id) + ":");
        Logger::info("  Instrucciones ejecutadas: " + std::to_string(stat.instructions_executed));
        Logger::info("  Ciclos totales: " + std::to_string(stat.total_cycles));
        Logger::info("  Ciclos ocupados: " + std::to_string(stat.total_cycles - stat.idle_cycles));
        Logger::info("  Ciclos idle: " + std::to_string(stat.idle_cycles));
        Logger::info("  Utilización: " + std::to_string(stat.utilization) + "%");
    }
    
    Logger::info("\n=== MÉTRICAS GLOBALES ===");
    Logger::info("Utilización total: " + std::to_string(getOverallUtilization()) + "%");
    Logger::info("IPC (Instructions Per Cycle): " + std::to_string(getIPC()));
    Logger::info("Makespan: " + std::to_string(makespan_) + " ciclos");
    Logger::info("Total instrucciones: " + std::to_string(total_instructions_));
}

// Guarda estadisticas de mapeo en un archivo
// Input: nombre del archivo de salida
void PEMapper::saveToFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo abrir archivo: " + filename);
        return;
    }
    
    file << "# PE Mapping and Statistics\n\n";
    
    file << "=== GLOBAL METRICS ===\n";
    file << "Total Instructions: " << total_instructions_ << "\n";
    file << "Makespan: " << makespan_ << " cycles\n";
    file << "Number of PEs: " << num_pes_ << "\n";
    file << "IPC (Instructions Per Cycle): " << std::fixed << std::setprecision(4) 
         << getIPC() << "\n";
    file << "Overall Utilization: " << std::fixed << std::setprecision(2) 
         << getOverallUtilization() << "%\n\n";
    
    file << "=== PER-PE STATISTICS ===\n\n";
    
    for (const auto& stat : statistics_) {
        file << "PE" << stat.pe_id << ":\n";
        file << "  Instructions Executed: " << stat.instructions_executed << "\n";
        file << "  Total Cycles: " << stat.total_cycles << "\n";
        file << "  Busy Cycles: " << (stat.total_cycles - stat.idle_cycles) << "\n";
        file << "  Idle Cycles: " << stat.idle_cycles << "\n";
        file << "  Utilization: " << std::fixed << std::setprecision(2) 
             << stat.utilization << "%\n";
        
        file << "  Instructions: [";
        for (size_t i = 0; i < stat.instruction_ids.size(); i++) {
            if (i > 0) file << ", ";
            file << stat.instruction_ids[i];
        }
        file << "]\n\n";
    }
    
    file << "=== SUMMARY TABLE ===\n";
    file << "PE | Instructions | Busy Cycles | Idle Cycles | Utilization\n";
    file << "---|--------------|-------------|-------------|------------\n";
    
    for (const auto& stat : statistics_) {
        file << std::setw(2) << stat.pe_id << " | "
             << std::setw(12) << stat.instructions_executed << " | "
             << std::setw(11) << (stat.total_cycles - stat.idle_cycles) << " | "
             << std::setw(11) << stat.idle_cycles << " | "
             << std::setw(10) << std::fixed << std::setprecision(2) 
             << stat.utilization << "%\n";
    }
    
    file.close();
    Logger::info("Mapeo guardado en: " + filename);
}
