#ifndef BASICBLOCK_H
#define BASICBLOCK_H

#include "../parser/Instruction.h"
#include <vector>
#include <memory>

// Representa un bloque basico del CFG
class BasicBlock {
private:
    int id;
    std::vector<Instruction> instructions;
    std::vector<int> predecessors;
    std::vector<int> successors;

    int startIndex;
    int endIndex;
    bool isLoopHeader;

public:
    BasicBlock(int blockId);

    void addInstruction(const Instruction& instr);
    void addPredecessor(int blockId);
    void addSuccessor(int blockId);

    int getId() const { return id; }
    const std::vector<Instruction>& getInstructions() const { return instructions; }
    const std::vector<int>& getPredecessors() const { return predecessors; }
    const std::vector<int>& getSuccessors() const { return successors; }

    void setStartIndex(int idx) { startIndex = idx; }
    void setEndIndex(int idx) { endIndex = idx; }
    int getStartIndex() const { return startIndex; }
    int getEndIndex() const { return endIndex; }

    void setLoopHeader(bool val) { isLoopHeader = val; }
    bool getIsLoopHeader() const { return isLoopHeader; }

    bool isEmpty() const { return instructions.empty(); }
    size_t size() const { return instructions.size(); }

    std::string toString() const;
};

#endif // BASICBLOCK_H
