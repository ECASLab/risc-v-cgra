#ifndef DFG_BUILDER_H
#define DFG_BUILDER_H

#include "DFGNode.h"
#include "../parser/Parser.h"
#include "../dependency/DependencyAnalyzer.h"
#include "../config/ConfigReader.h"
#include <vector>
#include <memory>
#include <map>

// Construye el Data Flow Graph a partir de instrucciones y dependencias
class DFGBuilder {
private:
    const Parser& parser;
    const DependencyAnalyzer& depAnalyzer;
    const ConfigReader& config;

    std::vector<std::unique_ptr<DFGNode>> nodes;
    std::map<int, int> instrIndexToNodeId;
    std::vector<int> rootNodes;
    std::vector<int> leafNodes;

public:
    DFGBuilder(const Parser& p, const DependencyAnalyzer& da, const ConfigReader& cfg);

    void build();
    void buildNodes();
    void buildEdges();
    void identifyRootsAndLeafs();

    const std::vector<std::unique_ptr<DFGNode>>& getNodes() const { return nodes; }
    const std::vector<int>& getRootNodes() const { return rootNodes; }
    const std::vector<int>& getLeafNodes() const { return leafNodes; }

    DFGNode* getNode(int nodeId);
    const DFGNode* getNode(int nodeId) const;

    void printDFG() const;
    bool saveDFGToFile(const std::string& filename) const;
    bool saveDotFile(const std::string& filename) const;
};

#endif // DFG_BUILDER_H
