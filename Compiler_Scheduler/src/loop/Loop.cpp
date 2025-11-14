#include "Loop.h"
#include <sstream>

// Constructor
// Input: ID del bloque header del loop
Loop::Loop(int header)
: headerId(header), tripCount(-1), isCountable(false),
complexity(LoopComplexity::COMPLEX), nestingLevel(0) {}

void Loop::addBodyBlock(int blockId) {
    bodyBlocks.push_back(blockId);
}

void Loop::addExitBlock(int blockId) {
    exitBlocks.push_back(blockId);
}

void Loop::setTripCount(int count) {
    tripCount = count;
    if (count > 0) {
        isCountable = true;
    }
}

void Loop::setCountable(bool val) {
    isCountable = val;
}

void Loop::setComplexity(LoopComplexity c) {
    complexity = c;
}

void Loop::setNestingLevel(int level) {
    nestingLevel = level;
}

// Evalua si el loop es candidato para ejecutarse en CGRA
// Criterios: complejidad no excesiva, tamano razonable, preferencia por countable
// Output: true si es candidato
bool Loop::isCGRACandidate() const {
    bool sizeOK = bodyBlocks.size() < 20;

    if (complexity == LoopComplexity::SIMPLE) {
        return sizeOK;
    }

    if (complexity == LoopComplexity::MODERATE) {
        return sizeOK && (isCountable || bodyBlocks.size() < 5);
    }

    return false;
}

std::string Loop::complexityToString() const {
    switch (complexity) {
        case LoopComplexity::SIMPLE:   return "SIMPLE";
        case LoopComplexity::MODERATE: return "MODERATE";
        case LoopComplexity::COMPLEX:  return "COMPLEX";
        default:                       return "UNKNOWN";
    }
}

// Genera representacion en texto del loop con sus propiedades
// Output: string con informacion del loop
std::string Loop::toString() const {
    std::stringstream ss;
    ss << "Loop @ BB" << headerId << "\n";
    ss << "  Nivel anidamiento: " << nestingLevel << "\n";
    ss << "  Complejidad: " << complexityToString() << "\n";
    ss << "  Trip count: " << (tripCount > 0 ? std::to_string(tripCount) : "DESCONOCIDO") << "\n";
    ss << "  Bloques en cuerpo: " << bodyBlocks.size() << "\n";
    ss << "  Bloques de salida: " << exitBlocks.size() << "\n";
    ss << "  Candidato CGRA: " << (isCGRACandidate() ? "SÍ" : "NO") << "\n";

    return ss.str();
}
