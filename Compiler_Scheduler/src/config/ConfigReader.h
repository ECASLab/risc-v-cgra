#ifndef CONFIG_READER_H
#define CONFIG_READER_H

#include <string>
#include <map>

// Lee y almacena configuracion de latencias y hardware
class ConfigReader {
private:
    std::map<std::string, int> latencies;

    int numPEs;
    int numRegisters;
    int memoryBanks;
    std::string topology;

    std::string arbiterPolicy;
    int arbiterGrantLatency;
    int arbiterContentionPenalty;

public:
    ConfigReader();

    bool loadLatencyConfig(const std::string& filename);
    bool loadHardwareConfig(const std::string& filename);

    int getLatency(const std::string& opcode) const;
    int getNumPEs() const { return numPEs; }
    int getNumRegisters() const { return numRegisters; }
    int getMemoryBanks() const { return memoryBanks; }
    std::string getTopology() const { return topology; }

    std::string getArbiterPolicy() const { return arbiterPolicy; }
    int getArbiterGrantLatency() const { return arbiterGrantLatency; }
    int getArbiterContentionPenalty() const { return arbiterContentionPenalty; }

    void setDefaultLatencies();
    void setDefaultHardware();
};

#endif // CONFIG_READER_H
