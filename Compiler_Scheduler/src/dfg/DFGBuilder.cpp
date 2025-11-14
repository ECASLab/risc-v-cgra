#include "DFGBuilder.h"
#include "../utils/Logger.h"
#include <fstream>
#include <algorithm>

// Constructor
// Input: parser con instrucciones, analizador de dependencias, configuracion
DFGBuilder::DFGBuilder(const Parser& p, const DependencyAnalyzer& da, const ConfigReader& cfg)
: parser(p), depAnalyzer(da), config(cfg) {}

// Construye el DFG completo: nodos, aristas y nodos especiales
void DFGBuilder::build() {
    Logger::info("Construyendo Data Flow Graph...");

    buildNodes();
    buildEdges();
    identifyRootsAndLeafs();

    Logger::info("DFG construido: " + std::to_string(nodes.size()) + " nodos");
    Logger::info("Nodos raíz: " + std::to_string(rootNodes.size()));
    Logger::info("Nodos hoja: " + std::to_string(leafNodes.size()));
}

// Crea un nodo del DFG por cada instruccion
// Asigna latencias segun el tipo de operacion
void DFGBuilder::buildNodes() {
    Logger::debug("Creando nodos del DFG...");

    const auto& instructions = parser.getInstructions();

    for (size_t i = 0; i < instructions.size(); i++) {
        const auto& instr = instructions[i];

        int latency = config.getLatency(instr.getOpcode());
        auto node = std::make_unique<DFGNode>(nodes.size(), i, instr, latency);

        instrIndexToNodeId[i] = nodes.size();

        nodes.push_back(std::move(node));
    }

    Logger::debug("Nodos creados: " + std::to_string(nodes.size()));
}

// Conecta nodos basandose en dependencias RAW y de memoria
// WAR y WAW se manejan durante el scheduling
void DFGBuilder::buildEdges() {
    Logger::debug("Conectando aristas del DFG...");

    const auto& dependencies = depAnalyzer.getDependencies();

    for (const auto& dep : dependencies) {
        int srcInstrIdx = dep->getSource();
        int dstInstrIdx = dep->getDest();

        if (instrIndexToNodeId.find(srcInstrIdx) != instrIndexToNodeId.end() &&
            instrIndexToNodeId.find(dstInstrIdx) != instrIndexToNodeId.end()) {

            int srcNodeId = instrIndexToNodeId[srcInstrIdx];
            int dstNodeId = instrIndexToNodeId[dstInstrIdx];

            // Solo aristas RAW y MEMORY (dependencias verdaderas)
            if (dep->getType() == DependencyType::RAW ||
                dep->getType() == DependencyType::MEMORY) {

                nodes[srcNodeId]->addSuccessor(dstNodeId);
                nodes[dstNodeId]->addPredecessor(srcNodeId);
            }
        }
    }

    Logger::debug("Aristas creadas");
}

// Identifica nodos raiz (sin predecesores) y hojas (sin sucesores)
void DFGBuilder::identifyRootsAndLeafs() {
    rootNodes.clear();
    leafNodes.clear();

    for (const auto& node : nodes) {
        if (node->getPredecessors().empty()) {
            rootNodes.push_back(node->getId());
        }
        if (node->getSuccessors().empty()) {
            leafNodes.push_back(node->getId());
        }
    }
}

// Obtiene un nodo por su ID
// Input: ID del nodo
// Output: puntero al nodo o nullptr si no existe
DFGNode* DFGBuilder::getNode(int nodeId) {
    if (nodeId >= 0 && nodeId < (int)nodes.size()) {
        return nodes[nodeId].get();
    }
    return nullptr;
}

const DFGNode* DFGBuilder::getNode(int nodeId) const {
    if (nodeId >= 0 && nodeId < (int)nodes.size()) {
        return nodes[nodeId].get();
    }
    return nullptr;
}

// Imprime el DFG en consola
void DFGBuilder::printDFG() const {
    Logger::info("=== DATA FLOW GRAPH ===");

    for (const auto& node : nodes) {
        std::cout << node->toString() << "\n\n";
    }
}

// Guarda el DFG en un archivo de texto
// Input: nombre del archivo de salida
// Output: true si tuvo exito
bool DFGBuilder::saveDFGToFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return false;
    }

    file << "# Data Flow Graph\n";
    file << "# Total nodos: " << nodes.size() << "\n";
    file << "# Nodos raíz: " << rootNodes.size() << "\n";
    file << "# Nodos hoja: " << leafNodes.size() << "\n\n";

    for (const auto& node : nodes) {
        file << node->toString() << "\n\n";
    }

    file.close();
    Logger::info("DFG guardado en: " + filename);
    return true;
}

// Guarda el DFG en formato DOT para visualizacion
// Resalta nodos en camino critico en rojo
// Input: nombre del archivo .dot
// Output: true si tuvo exito
bool DFGBuilder::saveDotFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return false;
    }

    file << "digraph DFG {\n";
    file << "  rankdir=TB;\n";
    file << "  node [shape=box];\n\n";

    // Nodos
    for (const auto& node : nodes) {
        std::string color = "lightblue";
        if (node->getIsOnCriticalPath()) {
            color = "red";
        }

        file << "  N" << node->getId() << " [label=\"";
        file << node->getInstruction().getOpcode();
        file << "\\nLat:" << node->getLatency();
        file << "\\nEST:" << node->getEarliestStartTime();
        file << "\", style=filled, fillcolor=" << color << "];\n";
    }

    file << "\n";

    // Aristas
    for (const auto& node : nodes) {
        for (int succId : node->getSuccessors()) {
            file << "  N" << node->getId() << " -> N" << succId;

            if (node->getIsOnCriticalPath() && nodes[succId]->getIsOnCriticalPath()) {
                file << " [color=red, penwidth=2.0]";
            }

            file << ";\n";
        }
    }

    file << "}\n";
    file.close();

    Logger::info("Archivo DOT del DFG guardado: " + filename);
    return true;
}
