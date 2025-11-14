#ifndef CFGBUILDER_H
#define CFGBUILDER_H

#include "BasicBlock.h"
#include "../parser/Parser.h"
#include <vector>
#include <memory>
#include <map>

// Construye el grafo de flujo de control (CFG)
class CFGBuilder {
private:
    const Parser& parser;
    std::vector<std::unique_ptr<BasicBlock>> blocks;
    std::map<int, int> instrToBlock;
    int blockCounter;

public:
    CFGBuilder(const Parser& p);

    void build();
    void identifyBlockBoundaries(std::vector<int>& boundaries);
    void createBlocks(const std::vector<int>& boundaries);
    void connectBlocks();

    const std::vector<std::unique_ptr<BasicBlock>>& getBlocks() const { return blocks; }

    void printCFG() const;
    bool saveCFGToFile(const std::string& filename) const;
    bool saveDotFile(const std::string& filename) const;
};

#endif // CFGBUILDER_H
