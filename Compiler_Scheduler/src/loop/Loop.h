#ifndef LOOP_H
#define LOOP_H

#include <vector>
#include <string>

enum class LoopComplexity {
    SIMPLE,
    MODERATE,
    COMPLEX
};

// Representa un loop detectado en el CFG
class Loop {
private:
    int headerId;
    std::vector<int> bodyBlocks;
    std::vector<int> exitBlocks;
    int tripCount;
    bool isCountable;
    LoopComplexity complexity;
    int nestingLevel;

public:
    Loop(int header);

    void addBodyBlock(int blockId);
    void addExitBlock(int blockId);
    void setTripCount(int count);
    void setCountable(bool val);
    void setComplexity(LoopComplexity c);
    void setNestingLevel(int level);

    int getHeaderId() const { return headerId; }
    const std::vector<int>& getBodyBlocks() const { return bodyBlocks; }
    const std::vector<int>& getExitBlocks() const { return exitBlocks; }
    int getTripCount() const { return tripCount; }
    bool getIsCountable() const { return isCountable; }
    LoopComplexity getComplexity() const { return complexity; }
    int getNestingLevel() const { return nestingLevel; }

    bool isCGRACandidate() const;
    std::string complexityToString() const;
    std::string toString() const;
};

#endif // LOOP_H
