#include "Dependency.h"
#include <sstream>

// Constructor
// Input: indices de instrucciones origen y destino, tipo de dependencia, recurso involucrado
Dependency::Dependency(int src, int dst, DependencyType t, const std::string& res)
: sourceInstrIndex(src), destInstrIndex(dst), type(t), resource(res), distance(0) {}

// Convierte el tipo de dependencia a string
// Output: string descriptivo del tipo (RAW, WAR, WAW, MEMORY)
std::string Dependency::typeToString() const {
    switch (type) {
        case DependencyType::RAW: return "RAW";
        case DependencyType::WAR: return "WAR";
        case DependencyType::WAW: return "WAW";
        case DependencyType::MEMORY: return "MEMORY";
        default: return "UNKNOWN";
    }
}

// Genera representacion en texto de la dependencia
// Output: string con formato "Instr[X] -> Instr[Y] (TYPE on resource)"
std::string Dependency::toString() const {
    std::stringstream ss;
    ss << "Instr[" << sourceInstrIndex << "] -> Instr[" << destInstrIndex << "] ";
    ss << "(" << typeToString() << " on " << resource << ")";
    if (distance > 0) {
        ss << " [distance=" << distance << "]";
    }
    return ss.str();
}
