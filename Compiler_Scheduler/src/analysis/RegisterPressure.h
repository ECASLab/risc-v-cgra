#ifndef REGISTER_PRESSURE_H
#define REGISTER_PRESSURE_H

#include "../dfg/DFGBuilder.h"
#include "../parser/Parser.h"
#include "../config/ConfigReader.h"
#include <map>
#include <set>
#include <vector>

// Rango de vida de un registro
struct LiveRange {
    std::string registerName;
    int birthTime;
    int deathTime;
    int length;

    LiveRange(const std::string& reg, int birth, int death)
    : registerName(reg), birthTime(birth), deathTime(death),
    length(death - birth) {}
};

// Analiza la presion de registros y necesidad de spilling
class RegisterPressure {
private:
    const DFGBuilder& dfgBuilder;
    const Parser& parser;
    const ConfigReader& config;

    std::vector<LiveRange> liveRanges;
    std::map<int, std::set<std::string>> liveAtTime;

    int maxPressure;
    int avgPressure;
    int numRegistersAvailable;
    bool needsSpilling;

public:
    RegisterPressure(const DFGBuilder& dfg, const Parser& p, const ConfigReader& cfg);

    void analyze();
    void computeLiveRanges();
    void computePressureAtEachTime();
    void evaluateSpillingNeed();

    int getMaxPressure() const { return maxPressure; }
    int getAvgPressure() const { return avgPressure; }
    bool getNeedsSpilling() const { return needsSpilling; }
    const std::vector<LiveRange>& getLiveRanges() const { return liveRanges; }

    void printAnalysis() const;
    bool saveAnalysisToFile(const std::string& filename) const;
};

#endif // REGISTER_PRESSURE_H
