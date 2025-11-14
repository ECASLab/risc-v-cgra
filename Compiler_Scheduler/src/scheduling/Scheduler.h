#ifndef SCHEDULER_H
#define SCHEDULER_H

#include <vector>
#include <map>
#include <set>
#include <queue>
#include "../parser/Parser.h"
#include "../dfg/DFGBuilder.h"
#include "../config/ConfigReader.h"
#include "../register_partitioning/RegisterPartitioner.h"
#include "../arbiter/Arbiter.h"

// Instrucción planificada con ciclo, PE y metadatos
struct ScheduledInstruction {
    int instruction_id;
    int cycle;
    int pe_id;
    int latency;
    bool is_critical;
    bool requires_bus;
    std::string opcode;
    std::string rd, rs1, rs2, imm, label;
};

// Ejecuta list scheduling con arbiter para asignar instrucciones a PEs y ciclos
class Scheduler {
public:
    Scheduler(const Parser& parser, 
              const DFGBuilder& dfg,
              const ConfigReader& config,
              const RegisterPartitioner& partitioner);
    ~Scheduler() = default;

    void schedule();
    const std::vector<ScheduledInstruction>& getSchedule() const { return schedule_; }
    int getMakespan() const { return makespan_; }
    void printSchedule() const;
    void saveToFile(const std::string& filename) const;
    const Arbiter& getArbiter() const { return arbiter_; }

private:
    const Parser& parser_;
    const DFGBuilder& dfg_;
    const ConfigReader& config_;
    const RegisterPartitioner& partitioner_;
    
    std::vector<ScheduledInstruction> schedule_;
    int makespan_;
    int num_pes_;
    
    Arbiter arbiter_;
    bool use_arbiter_;
    
    std::map<int, int> instruction_completion_time_;
    std::vector<int> pe_available_at_;
    std::set<int> scheduled_instructions_;
    
    int getInstructionPriority(int inst_id) const;
    bool isReady(int inst_id) const;
    int getEarliestStartCycle(int inst_id) const;
    int selectPE(int inst_id, int start_cycle);
    std::vector<int> getReadyInstructions() const;
    bool requiresBusAccess(const Instruction& inst) const;
    int selectPEWithArbiter(int inst_id, int start_cycle);
};

#endif // SCHEDULER_H
