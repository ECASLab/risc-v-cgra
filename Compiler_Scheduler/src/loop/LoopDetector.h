#ifndef LOOPDETECTOR_H
#define LOOPDETECTOR_H

#include "Loop.h"
#include "../cfg/CFGBuilder.h"
#include <vector>
#include <memory>
#include <set>
#include <map>

// Detecta loops en el CFG mediante analisis de back-edges
class LoopDetector {
private:
    const CFGBuilder& cfg;
    std::vector<std::unique_ptr<Loop>> loops;

    std::set<int> visited;
    std::set<int> inStack;
    std::map<int, int> blockToLoop;

public:
    LoopDetector(const CFGBuilder& cfgBuilder);

    void detectLoops();
    void findBackEdges(std::vector<std::pair<int, int>>& backEdges);
    void dfsBackEdge(int blockId, std::vector<std::pair<int, int>>& backEdges);
    void analyzeLoop(Loop* loop);
    void classifyComplexity(Loop* loop);

    const std::vector<std::unique_ptr<Loop>>& getLoops() const { return loops; }

    void printLoops() const;
    bool saveLoopsToFile(const std::string& filename) const;
};

#endif // LOOPDETECTOR_H
