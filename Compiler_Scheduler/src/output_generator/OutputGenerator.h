#ifndef OUTPUT_GENERATOR_H
#define OUTPUT_GENERATOR_H

#include <string>
#include "../scheduling/Scheduler.h"
#include "../mapping/PEMapper.h"
#include "../config/ConfigReader.h"
#include "../parser/Parser.h"

// Genera todos los archivos de salida del compilador
class OutputGenerator {
public:
    OutputGenerator(const Scheduler& scheduler,
                   const PEMapper& mapper,
                   const Parser& parser,
                   const ConfigReader& config);
    ~OutputGenerator() = default;

    void generateAll(const std::string& output_dir);
    void generateScheduleFile(const std::string& filename);
    void generateHardwareConfig(const std::string& filename);
    void generateMetricsFile(const std::string& filename);
    void generateVisualization(const std::string& filename);
    void generateCombinedOutput(const std::string& filename);
    void generateArbiterStats(const std::string& filename);
    void generateInitializedAssembly(const std::string& filename);

private:
    const Scheduler& scheduler_;
    const PEMapper& mapper_;
    const Parser& parser_;
    const ConfigReader& config_;
    
    double calculateSpeedup() const;
    double calculateEfficiency() const;
};

#endif // OUTPUT_GENERATOR_H
