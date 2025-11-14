#ifndef DEPENDENCY_ANALYZER_H
#define DEPENDENCY_ANALYZER_H

#include "Dependency.h"
#include "../parser/Parser.h"
#include "../loop/LoopDetector.h"
#include <vector>
#include <memory>
#include <map>
#include <set>

// Analiza dependencias de datos entre instrucciones
class DependencyAnalyzer {
private:
    const Parser& parser;
    const LoopDetector& loopDetector;

    std::vector<std::unique_ptr<Dependency>> dependencies;
    std::map<int, std::set<int>> dependencyGraph;

    std::map<std::string, int> lastWriter;
    std::map<std::string, std::vector<int>> readers;

public:
    DependencyAnalyzer(const Parser& p, const LoopDetector& ld);

    void analyze();
    void analyzeRAW();
    void analyzeWAR();
    void analyzeWAW();
    void analyzeMemoryDependencies();

    const std::vector<std::unique_ptr<Dependency>>& getDependencies() const {
        return dependencies;
    }

    const std::map<int, std::set<int>>& getDependencyGraph() const {
        return dependencyGraph;
    }

    void printDependencies() const;
    bool saveDependenciesToFile(const std::string& filename) const;
    bool saveDotFile(const std::string& filename) const;

private:
    void addDependency(int src, int dst, DependencyType type, const std::string& resource);
};

#endif // DEPENDENCY_ANALYZER_H
