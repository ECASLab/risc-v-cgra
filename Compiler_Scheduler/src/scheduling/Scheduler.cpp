#include "Scheduler.h"
#include "../utils/Logger.h"
#include <fstream>
#include <algorithm>
#include <limits>

// Constructor: inicializa scheduler con parser, DFG, config y particionador
// Input: parser, dfg, config, partitioner (componentes del compilador)
// Output: instancia de Scheduler con arbiter Round-Robin habilitado
Scheduler::Scheduler(const Parser& parser,
                     const DFGBuilder& dfg,
                     const ConfigReader& config,
                     const RegisterPartitioner& partitioner)
    : parser_(parser), dfg_(dfg), config_(config), partitioner_(partitioner),
      makespan_(0), num_pes_(config.getNumPEs()),
      arbiter_(config.getNumPEs(), Arbiter::Policy::ROUND_ROBIN),
      use_arbiter_(true) {
    
    pe_available_at_.resize(num_pes_, 0);
    arbiter_.setGrantLatency(config.getArbiterGrantLatency());
    
    Logger::info("Scheduler inicializado con Arbiter Round-Robin");
}

// Ejecuta list scheduling con prioridades, asigna instrucciones a PEs y ciclos
// Input: ninguno (usa parser_, dfg_, arbiter_ internos)
// Output: schedule_ completo con makespan calculado
void Scheduler::schedule() {
    Logger::info("Iniciando List Scheduling...");
    
    schedule_.clear();
    scheduled_instructions_.clear();
    instruction_completion_time_.clear();
    std::fill(pe_available_at_.begin(), pe_available_at_.end(), 0);
    
    int total_instructions = parser_.getInstructions().size();
    int current_cycle = 0;
    
    auto cmp = [this](int a, int b) {
        return getInstructionPriority(a) < getInstructionPriority(b);
    };
    
    while (scheduled_instructions_.size() < static_cast<size_t>(total_instructions)) {
        std::vector<int> ready = getReadyInstructions();
        
        if (ready.empty()) {
            current_cycle++;
            if (use_arbiter_) {
                arbiter_.advanceCycle();
            }
            if (current_cycle > 10000) {
                Logger::error("Scheduling timeout - posible deadlock");
                break;
            }
            continue;
        }
        
        std::sort(ready.begin(), ready.end(), cmp);
        
        std::set<int> pes_used_this_cycle;
        
        for (int inst_id : ready) {
            int earliest_start = getEarliestStartCycle(inst_id);
            
            if (earliest_start > current_cycle) {
                continue;
            }
            
            const Instruction& inst = parser_.getInstructions()[inst_id];
            bool needs_bus = requiresBusAccess(inst);
            
            if (use_arbiter_ && needs_bus) {
                int pe_id = selectPEWithArbiter(inst_id, current_cycle);
                
                if (pe_id < 0 || pes_used_this_cycle.count(pe_id) > 0) {
                    continue;
                }
                
                pes_used_this_cycle.insert(pe_id);
                
                const DFGNode* node = dfg_.getNode(inst_id);
                
                ScheduledInstruction sched;
                sched.instruction_id = inst_id;
                sched.cycle = current_cycle;
                sched.pe_id = pe_id;
                sched.latency = node ? node->getLatency() : 1;
                sched.is_critical = node ? node->getIsOnCriticalPath() : false;
                sched.requires_bus = true;
                sched.opcode = inst.getOpcode();
                sched.rd = inst.getRd();
                sched.rs1 = inst.getRs1();
                sched.rs2 = inst.getRs2();
                sched.imm = inst.hasImmediateValue() ? std::to_string(inst.getImmediate()) : "";
                sched.label = inst.getLabel();
                
                schedule_.push_back(sched);
                scheduled_instructions_.insert(inst_id);
                
                int completion_time = current_cycle + sched.latency;
                instruction_completion_time_[inst_id] = completion_time;
                pe_available_at_[pe_id] = completion_time;
                
                makespan_ = std::max(makespan_, completion_time);
                
                Logger::debug("Scheduled (BUS): Inst[" + std::to_string(inst_id) + "] " + 
                             inst.getOpcode() + " @ cycle " + std::to_string(current_cycle) + 
                             " on PE" + std::to_string(pe_id));
                
            } else {
                int pe_id = selectPE(inst_id, current_cycle);
                
                if (pe_id < 0) {
                    continue;
                }
                
                const DFGNode* node = dfg_.getNode(inst_id);
                
                ScheduledInstruction sched;
                sched.instruction_id = inst_id;
                sched.cycle = current_cycle;
                sched.pe_id = pe_id;
                sched.latency = node ? node->getLatency() : 1;
                sched.is_critical = node ? node->getIsOnCriticalPath() : false;
                sched.requires_bus = false;
                sched.opcode = inst.getOpcode();
                sched.rd = inst.getRd();
                sched.rs1 = inst.getRs1();
                sched.rs2 = inst.getRs2();
                sched.imm = inst.hasImmediateValue() ? std::to_string(inst.getImmediate()) : "";
                sched.label = inst.getLabel();
                
                schedule_.push_back(sched);
                scheduled_instructions_.insert(inst_id);
                
                int completion_time = current_cycle + sched.latency;
                instruction_completion_time_[inst_id] = completion_time;
                pe_available_at_[pe_id] = completion_time;
                
                makespan_ = std::max(makespan_, completion_time);
                
                Logger::debug("Scheduled (LOCAL): Inst[" + std::to_string(inst_id) + "] " + 
                             inst.getOpcode() + " @ cycle " + std::to_string(current_cycle) + 
                             " on PE" + std::to_string(pe_id));
            }
        }
        
        current_cycle++;
        if (use_arbiter_) {
            arbiter_.advanceCycle();
        }
    }
    
    Logger::info("Scheduling completado: " + std::to_string(schedule_.size()) + 
                 " instrucciones en " + std::to_string(makespan_) + " ciclos");
    
    if (use_arbiter_) {
        Logger::info("\n=== Estadísticas del Arbiter ===");
        Logger::info("Total accesos al bus: " + std::to_string(arbiter_.getTotalBusAccesses()));
        Logger::info("Total contenciones: " + std::to_string(arbiter_.getTotalContentions()));
        Logger::info("Utilización del bus: " + std::to_string(arbiter_.getBusUtilization()) + "%");
        
        auto contentions = arbiter_.getContentionsByPE();
        Logger::info("\nContenciones por PE:");
        for (const auto& [pe, count] : contentions) {
            Logger::info("  PE" + std::to_string(pe) + ": " + std::to_string(count));
        }
    }
}

// Verifica si una instrucción está lista para ejecutar (predecesores completados)
// Input: inst_id (ID de la instrucción)
// Output: true si está lista, false si no
bool Scheduler::isReady(int inst_id) const {
    if (scheduled_instructions_.count(inst_id) > 0) {
        return false;
    }
    
    const DFGNode* node = dfg_.getNode(inst_id);
    if (!node) return true;
    
    for (int pred_id : node->getPredecessors()) {
        if (scheduled_instructions_.count(pred_id) == 0) {
            return false;
        }
    }
    
    return true;
}

// Calcula el ciclo más temprano en que una instrucción puede iniciar
// Input: inst_id (ID de la instrucción)
// Output: ciclo más temprano de inicio
int Scheduler::getEarliestStartCycle(int inst_id) const {
    int earliest = 0;
    
    const DFGNode* node = dfg_.getNode(inst_id);
    if (!node) return earliest;
    
    for (int pred_id : node->getPredecessors()) {
        auto it = instruction_completion_time_.find(pred_id);
        if (it != instruction_completion_time_.end()) {
            earliest = std::max(earliest, it->second);
        }
    }
    
    return earliest;
}

// Selecciona el mejor PE para una instrucción considerando registros y disponibilidad
// Input: inst_id (ID de instrucción), start_cycle (ciclo de inicio)
// Output: ID del PE seleccionado o -1 si no hay disponible
int Scheduler::selectPE(int inst_id, int start_cycle) {
    const Instruction& inst = parser_.getInstructions()[inst_id];
    
    std::set<int> required_pes = partitioner_.getRequiredPEs(inst);
    
    int preferred_pe = -1;
    std::string rd = inst.getRd();
    if (!rd.empty() && rd != "-") {
        preferred_pe = partitioner_.getRegisterOwner(rd);
    }
    
    int best_pe = -1;
    int min_wait_time = std::numeric_limits<int>::max();
    
    for (int pe = 0; pe < num_pes_; pe++) {
        if (preferred_pe >= 0 && pe != preferred_pe) {
            continue;
        }
        
        int available_at = pe_available_at_[pe];
        if (available_at <= start_cycle) {
            return pe;
        }
        
        int wait_time = available_at - start_cycle;
        if (wait_time < min_wait_time) {
            min_wait_time = wait_time;
            best_pe = pe;
        }
    }
    
    if (best_pe < 0 || preferred_pe < 0) {
        for (int pe = 0; pe < num_pes_; pe++) {
            if (pe_available_at_[pe] <= start_cycle) {
                return pe;
            }
            
            int wait_time = pe_available_at_[pe] - start_cycle;
            if (wait_time < min_wait_time) {
                min_wait_time = wait_time;
                best_pe = pe;
            }
        }
    }
    
    return best_pe;
}

// Obtiene todas las instrucciones listas para ejecutar
// Input: ninguno (usa scheduled_instructions_ y dfg_ internos)
// Output: vector de IDs de instrucciones listas
std::vector<int> Scheduler::getReadyInstructions() const {
    std::vector<int> ready;
    
    for (size_t i = 0; i < parser_.getInstructions().size(); i++) {
        if (isReady(i)) {
            ready.push_back(i);
        }
    }
    
    return ready;
}

// Calcula prioridad de instrucción (camino crítico + slack + sucesores)
// Input: inst_id (ID de instrucción)
// Output: valor de prioridad (mayor = más prioritario)
int Scheduler::getInstructionPriority(int inst_id) const {
    const DFGNode* node = dfg_.getNode(inst_id);
    if (!node) return 0;
    
    int priority = 0;
    
    if (node->getIsOnCriticalPath()) {
        priority += 10000;
    }
    
    priority += (1000 - node->getSlack());
    priority += node->getSuccessors().size() * 100;
    
    return priority;
}

// Imprime el schedule completo a consola agrupado por ciclo
void Scheduler::printSchedule() const {
    Logger::info("\n=== SCHEDULE GENERADO ===");
    Logger::info("Makespan: " + std::to_string(makespan_) + " ciclos");
    Logger::info("Total instrucciones: " + std::to_string(schedule_.size()));
    
    std::map<int, std::vector<ScheduledInstruction>> by_cycle;
    for (const auto& si : schedule_) {
        by_cycle[si.cycle].push_back(si);
    }
    
    Logger::info("\nSchedule por ciclo:");
    for (const auto& [cycle, insts] : by_cycle) {
        Logger::info("\nCiclo " + std::to_string(cycle) + ":");
        for (const auto& si : insts) {
            std::string line = "  PE" + std::to_string(si.pe_id) + ": [" + 
                              std::to_string(si.instruction_id) + "] " + si.opcode;
            if (!si.rd.empty() && si.rd != "-") line += " rd=" + si.rd;
            if (!si.rs1.empty() && si.rs1 != "-") line += " rs1=" + si.rs1;
            if (!si.rs2.empty() && si.rs2 != "-") line += " rs2=" + si.rs2;
            if (si.is_critical) line += " [CRITICAL]";
            Logger::info(line);
        }
    }
}

// Guarda el schedule en archivo de texto con formato tabla
// Input: filename (ruta del archivo)
// Output: archivo con schedule detallado por ciclo
void Scheduler::saveToFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo abrir archivo: " + filename);
        return;
    }
    
    file << "# Schedule Generated by CGRA Compiler\n";
    file << "# Makespan: " << makespan_ << " cycles\n";
    file << "# Total Instructions: " << schedule_.size() << "\n";
    file << "# Number of PEs: " << num_pes_ << "\n\n";
    
    file << "# Format: CYCLE | PE | INST_ID | OPCODE | RD | RS1 | RS2 | IMM | LATENCY | CRITICAL\n\n";
    
    std::map<int, std::vector<ScheduledInstruction>> by_cycle;
    for (const auto& si : schedule_) {
        by_cycle[si.cycle].push_back(si);
    }
    
    for (const auto& [cycle, insts] : by_cycle) {
        for (const auto& si : insts) {
            file << cycle << " | "
                 << si.pe_id << " | "
                 << si.instruction_id << " | "
                 << si.opcode << " | "
                 << (si.rd.empty() ? "-" : si.rd) << " | "
                 << (si.rs1.empty() ? "-" : si.rs1) << " | "
                 << (si.rs2.empty() ? "-" : si.rs2) << " | "
                 << (si.imm.empty() ? "-" : si.imm) << " | "
                 << si.latency << " | "
                 << (si.is_critical ? "CRIT" : "-") << "\n";
        }
    }
    
    file.close();
    Logger::info("Schedule guardado en: " + filename);
}

// Verifica si una instrucción requiere acceso al bus (load/store o inter-PE)
// Input: inst (instrucción a verificar)
// Output: true si requiere bus, false si es operación local
bool Scheduler::requiresBusAccess(const Instruction& inst) const {
    std::string opcode = inst.getOpcode();
    
    if (opcode == "lw" || opcode == "lh" || opcode == "lb" ||
        opcode == "lbu" || opcode == "lhu" ||
        opcode == "sw" || opcode == "sh" || opcode == "sb") {
        return true;
    }
    
    if (opcode == "beq" || opcode == "bne" || opcode == "blt" || 
        opcode == "bge" || opcode == "bltu" || opcode == "bgeu" ||
        opcode == "jal" || opcode == "jalr") {
        return false;
    }
    
    std::string rd = inst.getRd();
    std::string rs1 = inst.getRs1();
    std::string rs2 = inst.getRs2();
    
    if ((rd.empty() || rd == "-") && 
        (rs1.empty() || rs1 == "-") && 
        (rs2.empty() || rs2 == "-")) {
        return false;
    }
    
    int rd_pe = (rd.empty() || rd == "-") ? -1 : partitioner_.getRegisterOwner(rd);
    int rs1_pe = (rs1.empty() || rs1 == "-") ? -1 : partitioner_.getRegisterOwner(rs1);
    int rs2_pe = (rs2.empty() || rs2 == "-") ? -1 : partitioner_.getRegisterOwner(rs2);
    
    if (rd_pe >= 0 && rs1_pe >= 0 && rd_pe != rs1_pe) {
        return true;
    }
    if (rd_pe >= 0 && rs2_pe >= 0 && rd_pe != rs2_pe) {
        return true;
    }
    if (rs1_pe >= 0 && rs2_pe >= 0 && rs1_pe != rs2_pe) {
        return true;
    }
    
    return false;
}

// Selecciona PE usando arbiter para instrucciones que requieren bus
// Input: inst_id (ID de instrucción), start_cycle (ciclo de inicio)
// Output: ID del PE con grant del arbiter o -1 si no disponible
int Scheduler::selectPEWithArbiter(int inst_id, int start_cycle) {
    const Instruction& inst = parser_.getInstructions()[inst_id];
    
    bool needs_bus = requiresBusAccess(inst);
    
    if (!needs_bus) {
        return selectPE(inst_id, start_cycle);
    }
    
    std::string rd = inst.getRd();
    int preferred_pe = -1;
    if (!rd.empty() && rd != "-") {
        preferred_pe = partitioner_.getRegisterOwner(rd);
    }
    
    if (preferred_pe >= 0 && pe_available_at_[preferred_pe] <= start_cycle) {
        int earliest = getEarliestStartCycle(inst_id);
        if (start_cycle >= earliest) {
            arbiter_.requestBusAccess(preferred_pe, start_cycle);
            return preferred_pe;
        }
    }
    
    for (int pe = 0; pe < num_pes_; pe++) {
        if (pe_available_at_[pe] <= start_cycle) {
            int earliest = getEarliestStartCycle(inst_id);
            if (start_cycle >= earliest) {
                arbiter_.requestBusAccess(pe, start_cycle);
                return pe;
            }
        }
    }
    
    return -1;
}
