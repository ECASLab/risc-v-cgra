#include "CFGBuilder.h"
#include "../utils/Logger.h"
#include <fstream>
#include <algorithm>

// Constructor
// Input: parser con instrucciones parseadas
CFGBuilder::CFGBuilder(const Parser& p) : parser(p), blockCounter(0) {}

// Construye el CFG completo identificando bloques y sus conexiones
void CFGBuilder::build() {
    Logger::info("Construyendo CFG...");

    // Identificar límites de bloques básicos
    std::vector<int> boundaries;
    identifyBlockBoundaries(boundaries);

    // Crear bloques básicos
    createBlocks(boundaries);

    // Conectar bloques (aristas del CFG)
    connectBlocks();

    Logger::info("CFG construido: " + std::to_string(blocks.size()) + " bloques básicos");
}

// Identifica los limites de bloques basicos (leaders)
// Input/Output: vector de indices donde inician bloques basicos
void CFGBuilder::identifyBlockBoundaries(std::vector<int>& boundaries) {
    Logger::debug("Identificando límites de bloques básicos...");

    const auto& instructions = parser.getInstructions();
    const auto& labels = parser.getLabels();

    // Primera instrucción siempre es inicio de bloque (leader)
    boundaries.push_back(0);

    for (size_t i = 0; i < instructions.size(); i++) {
        const Instruction& instr = instructions[i];

        // Si es branch o jump, la siguiente instrucción inicia nuevo bloque
        if (instr.isBranchOperation() || instr.isJumpOperation()) {
            if (i + 1 < instructions.size()) {
                boundaries.push_back(i + 1);
            }

            // El target del jump/branch también es inicio de bloque
            std::string targetLabel = instr.getLabel();
            if (!targetLabel.empty() && labels.find(targetLabel) != labels.end()) {
                int targetIndex = labels.at(targetLabel);
                boundaries.push_back(targetIndex);
            }
        }
    }

    // Ordenar y eliminar duplicados
    std::sort(boundaries.begin(), boundaries.end());
    boundaries.erase(std::unique(boundaries.begin(), boundaries.end()), boundaries.end());

    Logger::debug("Límites identificados: " + std::to_string(boundaries.size()));
}

// Crea los bloques basicos a partir de los limites identificados
// Input: vector con indices de inicio de cada bloque
void CFGBuilder::createBlocks(const std::vector<int>& boundaries) {
    Logger::debug("Creando bloques básicos...");

    const auto& instructions = parser.getInstructions();

    for (size_t i = 0; i < boundaries.size(); i++) {
        int start = boundaries[i];
        int end = (i + 1 < boundaries.size()) ? boundaries[i + 1] - 1 : instructions.size() - 1;

        auto block = std::make_unique<BasicBlock>(blockCounter++);
        block->setStartIndex(start);
        block->setEndIndex(end);

        // Agregar instrucciones al bloque
        for (int j = start; j <= end; j++) {
            block->addInstruction(instructions[j]);
            instrToBlock[j] = block->getId();
        }

        blocks.push_back(std::move(block));
    }

    Logger::debug("Bloques creados: " + std::to_string(blocks.size()));
}

// Conecta los bloques basicos creando aristas del CFG
// Analiza branches, jumps y fall-through para determinar flujo de control
void CFGBuilder::connectBlocks() {
    Logger::debug("Conectando bloques (creando aristas)...");

    const auto& labels = parser.getLabels();

    for (size_t i = 0; i < blocks.size(); i++) {
        BasicBlock* block = blocks[i].get();
        const auto& instructions = block->getInstructions();

        if (instructions.empty()) continue;

        const Instruction& lastInstr = instructions.back();

        if (lastInstr.isBranchOperation()) {
            // Branch tiene 2 sucesores: tomado y no tomado

            // Sucesor 1: branch tomado (target)
            std::string targetLabel = lastInstr.getLabel();
            if (!targetLabel.empty() && labels.find(targetLabel) != labels.end()) {
                int targetIndex = labels.at(targetLabel);
                if (instrToBlock.find(targetIndex) != instrToBlock.end()) {
                    int targetBlockId = instrToBlock[targetIndex];
                    block->addSuccessor(targetBlockId);
                    blocks[targetBlockId]->addPredecessor(block->getId());
                }
            }

            // Sucesor 2: fall-through (siguiente bloque)
            if (i + 1 < blocks.size()) {
                block->addSuccessor(blocks[i + 1]->getId());
                blocks[i + 1]->addPredecessor(block->getId());
            }
        }
        else if (lastInstr.isJumpOperation()) {
            // Jump tiene 1 sucesor: target
            std::string targetLabel = lastInstr.getLabel();
            if (!targetLabel.empty() && labels.find(targetLabel) != labels.end()) {
                int targetIndex = labels.at(targetLabel);
                if (instrToBlock.find(targetIndex) != instrToBlock.end()) {
                    int targetBlockId = instrToBlock[targetIndex];
                    block->addSuccessor(targetBlockId);
                    blocks[targetBlockId]->addPredecessor(block->getId());
                }
            }
        }
        else {
            // Fall-through normal
            if (i + 1 < blocks.size()) {
                block->addSuccessor(blocks[i + 1]->getId());
                blocks[i + 1]->addPredecessor(block->getId());
            }
        }
    }

    Logger::debug("Aristas creadas");
}

// Imprime el CFG en consola
void CFGBuilder::printCFG() const {
    Logger::info("=== CONTROL FLOW GRAPH ===");
    for (const auto& block : blocks) {
        std::cout << block->toString() << std::endl;
    }
}

// Guarda el CFG en un archivo de texto
// Input: nombre del archivo de salida
// Output: archivo con informacion detallada del CFG, retorna true si tuvo exito
bool CFGBuilder::saveCFGToFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return false;
    }

    file << "# Control Flow Graph\n";
    file << "# Total bloques: " << blocks.size() << "\n\n";

    for (const auto& block : blocks) {
        file << block->toString() << "\n";

        // Mostrar instrucciones del bloque
        const auto& instructions = block->getInstructions();
        for (const auto& instr : instructions) {
            file << "    " << instr.toString() << "\n";
        }
        file << "\n";
    }

    file.close();
    Logger::info("CFG guardado en: " + filename);
    return true;
}

// Guarda el CFG en formato DOT para visualizacion grafica
// Input: nombre del archivo .dot de salida
// Output: archivo DOT compatible con Graphviz, retorna true si tuvo exito
bool CFGBuilder::saveDotFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return false;
    }

    file << "digraph CFG {\n";
    file << "  rankdir=TB;\n";
    file << "  node [shape=box, style=filled, fillcolor=lightblue];\n\n";

    // Nodos
    for (const auto& block : blocks) {
        file << "  BB" << block->getId() << " [label=\"BB" << block->getId();
        file << "\\n" << block->size() << " instrs";
        if (block->getIsLoopHeader()) {
            file << "\\n(LOOP HEADER)";
        }
        file << "\"];\n";
    }

    file << "\n";

    // Aristas
    for (const auto& block : blocks) {
        for (int succ : block->getSuccessors()) {
            file << "  BB" << block->getId() << " -> BB" << succ << ";\n";
        }
    }

    file << "}\n";
    file.close();

    Logger::info("Archivo DOT guardado: " + filename);
    Logger::info("Generar imagen con: dot -Tpng " + filename + " -o cfg.png");
    return true;
}
