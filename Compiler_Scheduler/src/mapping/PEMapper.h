#ifndef PE_MAPPER_H
#define PE_MAPPER_H

#include <vector>
#include <map>
#include "../scheduling/Scheduler.h"
#include "../config/ConfigReader.h"

// Estadisticas por PE
struct PEStatistics {
    int pe_id;
    int instructions_executed;
    int total_cycles;
    int idle_cycles;
    double utilization;
    std::vector<int> instruction_ids;
};

// Analiza y reporta el mapeo de instrucciones a PEs
class PEMapper {
public:
    PEMapper(const Scheduler& scheduler, const ConfigReader& config);
    ~PEMapper() = default;

    void analyzeMapping();
    const std::vector<PEStatistics>& getStatistics() const { return statistics_; }
    double getOverallUtilization() const;
    double getIPC() const;
    void printMapping() const;
    void saveToFile(const std::string& filename) const;

private:
    const Scheduler& scheduler_;
    const ConfigReader& config_;
    
    std::vector<PEStatistics> statistics_;
    int makespan_;
    int num_pes_;
    int total_instructions_;
};

#endif // PE_MAPPER_H
