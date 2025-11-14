#ifndef CRITICAL_PATH_H
#define CRITICAL_PATH_H

#include "../dfg/DFGBuilder.h"
#include <vector>

// Analiza el camino critico del DFG y calcula metricas de scheduling
class CriticalPath {
private:
    DFGBuilder& dfgBuilder;

    int criticalPathLength;
    std::vector<int> criticalPathNodes;
    double averageParallelism;

public:
    CriticalPath(DFGBuilder& dfg);

    void analyze();
    void computeASAP();
    void computeALAP();
    void identifyCriticalPath();
    void computeParallelism();

    int getCriticalPathLength() const { return criticalPathLength; }
    const std::vector<int>& getCriticalPathNodes() const { return criticalPathNodes; }
    double getAverageParallelism() const { return averageParallelism; }

    void printAnalysis() const;
    bool saveAnalysisToFile(const std::string& filename) const;
};

#endif // CRITICAL_PATH_H
