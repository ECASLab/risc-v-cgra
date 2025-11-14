#include "BasicBlock.h"
#include <sstream>

// Constructor
// Input: ID unico del bloque basico
BasicBlock::BasicBlock(int blockId)
: id(blockId), startIndex(-1), endIndex(-1), isLoopHeader(false) {}

// Agrega una instruccion al bloque basico
// Input: instruccion a agregar
void BasicBlock::addInstruction(const Instruction& instr) {
    instructions.push_back(instr);
}

// Agrega un bloque predecesor (evita duplicados)
// Input: ID del bloque predecesor
void BasicBlock::addPredecessor(int blockId) {
    // Evitar duplicados
    for (int pred : predecessors) {
        if (pred == blockId) return;
    }
    predecessors.push_back(blockId);
}

// Agrega un bloque sucesor (evita duplicados)
// Input: ID del bloque sucesor
void BasicBlock::addSuccessor(int blockId) {
    // Evitar duplicados
    for (int succ : successors) {
        if (succ == blockId) return;
    }
    successors.push_back(blockId);
}

// Genera una representacion en texto del bloque basico
// Output: string con informacion del bloque (ID, predecesores, sucesores)
std::string BasicBlock::toString() const {
    std::stringstream ss;
    ss << "BB" << id << " [" << startIndex << "-" << endIndex << "]";
    if (isLoopHeader) ss << " (LOOP HEADER)";
    ss << "\n  Predecesores: [";
    for (size_t i = 0; i < predecessors.size(); i++) {
        ss << "BB" << predecessors[i];
        if (i < predecessors.size() - 1) ss << ", ";
    }
    ss << "]\n  Sucesores: [";
    for (size_t i = 0; i < successors.size(); i++) {
        ss << "BB" << successors[i];
        if (i < successors.size() - 1) ss << ", ";
    }
    ss << "]\n  Instrucciones: " << instructions.size() << "\n";

    return ss.str();
}
