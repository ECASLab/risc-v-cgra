#include "DFGNode.h"
#include <sstream>

// Constructor
// Input: ID del nodo, indice de instruccion, instruccion, latencia
DFGNode::DFGNode(int nodeId, int instrIdx, const Instruction& instr, int lat)
: id(nodeId), instructionIndex(instrIdx), instruction(instr), latency(lat),
earliestStartTime(0), latestStartTime(0), slack(0),
isOnCriticalPath(false), depth(0) {}

void DFGNode::addPredecessor(int nodeId) {
    predecessors.push_back(nodeId);
}

void DFGNode::addSuccessor(int nodeId) {
    successors.push_back(nodeId);
}

// Genera representacion en texto del nodo con toda su informacion
// Output: string con detalles del nodo
std::string DFGNode::toString() const {
    std::stringstream ss;
    ss << "Node " << id << " [Instr " << instructionIndex << "]: "
    << instruction.getOpcode();

    if (!instruction.getRd().empty()) {
        ss << " rd=" << instruction.getRd();
    }
    if (!instruction.getRs1().empty()) {
        ss << " rs1=" << instruction.getRs1();
    }
    if (!instruction.getRs2().empty()) {
        ss << " rs2=" << instruction.getRs2();
    }

    ss << "\n  Latency: " << latency;
    ss << ", EST: " << earliestStartTime;
    ss << ", LST: " << latestStartTime;
    ss << ", Slack: " << slack;

    if (isOnCriticalPath) {
        ss << " [CRITICAL PATH]";
    }

    ss << "\n  Predecessors: [";
    for (size_t i = 0; i < predecessors.size(); i++) {
        ss << predecessors[i];
        if (i < predecessors.size() - 1) ss << ", ";
    }
    ss << "]\n  Successors: [";
    for (size_t i = 0; i < successors.size(); i++) {
        ss << successors[i];
        if (i < successors.size() - 1) ss << ", ";
    }
    ss << "]";

    return ss.str();
}
