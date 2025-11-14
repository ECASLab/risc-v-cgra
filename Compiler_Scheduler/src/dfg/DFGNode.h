#ifndef DFG_NODE_H
#define DFG_NODE_H

#include "../parser/Instruction.h"
#include <vector>
#include <string>
#include <memory>

// Representa un nodo del DFG correspondiente a una instruccion
class DFGNode {
private:
    int id;
    int instructionIndex;
    Instruction instruction;

    std::vector<int> predecessors;
    std::vector<int> successors;

    int latency;
    int earliestStartTime;
    int latestStartTime;
    int slack;
    bool isOnCriticalPath;
    int depth;

public:
    DFGNode(int nodeId, int instrIdx, const Instruction& instr, int lat);

    int getId() const { return id; }
    int getInstructionIndex() const { return instructionIndex; }
    const Instruction& getInstruction() const { return instruction; }
    int getLatency() const { return latency; }
    int getEarliestStartTime() const { return earliestStartTime; }
    int getLatestStartTime() const { return latestStartTime; }
    int getSlack() const { return slack; }
    bool getIsOnCriticalPath() const { return isOnCriticalPath; }
    int getDepth() const { return depth; }

    const std::vector<int>& getPredecessors() const { return predecessors; }
    const std::vector<int>& getSuccessors() const { return successors; }

    void setEarliestStartTime(int time) { earliestStartTime = time; }
    void setLatestStartTime(int time) { latestStartTime = time; }
    void setSlack(int s) { slack = s; }
    void setIsOnCriticalPath(bool val) { isOnCriticalPath = val; }
    void setDepth(int d) { depth = d; }

    void addPredecessor(int nodeId);
    void addSuccessor(int nodeId);

    std::string toString() const;
};

#endif // DFG_NODE_H
