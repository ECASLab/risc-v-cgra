#ifndef REGISTER_PARTITIONER_H
#define REGISTER_PARTITIONER_H

#include <vector>
#include <map>
#include <string>
#include <set>
#include "../parser/Instruction.h"
#include "../config/ConfigReader.h"

// Partición de registros asignada a un PE
struct RegisterPartition {
    int pe_id;
    std::set<std::string> registers;
    int start_reg;
    int end_reg;
};

// Divide registros equitativamente entre PEs
class RegisterPartitioner {
public:
    RegisterPartitioner(const ConfigReader& config);
    ~RegisterPartitioner() = default;

    void createPartitions();
    int getRegisterOwner(const std::string& reg) const;
    bool hasCrossPEDependency(const Instruction& inst) const;
    std::set<int> getRequiredPEs(const Instruction& inst) const;
    void printPartitioning() const;
    void saveToFile(const std::string& filename) const;
    
    const std::vector<RegisterPartition>& getPartitions() const { return partitions_; }
    int getNumPEs() const { return num_pes_; }

private:
    int num_pes_;
    int num_registers_;
    std::vector<RegisterPartition> partitions_;
    std::map<std::string, int> register_to_pe_;
    
    int getRegisterNumber(const std::string& reg) const;
};

#endif // REGISTER_PARTITIONER_H
