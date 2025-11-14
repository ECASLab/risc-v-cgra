#include "LoopDetector.h"
#include "../utils/Logger.h"
#include <fstream>
#include <algorithm>

// Constructor
// Input: CFG construido
LoopDetector::LoopDetector(const CFGBuilder& cfgBuilder) : cfg(cfgBuilder) {}

// Detecta todos los loops del CFG mediante analisis de back-edges
void LoopDetector::detectLoops() {
    Logger::info("Detectando loops...");

    std::vector<std::pair<int, int>> backEdges;
    findBackEdges(backEdges);

    Logger::debug("Back-edges encontrados: " + std::to_string(backEdges.size()));

    // Para cada back-edge, crear un loop y encontrar su natural loop
    for (const auto& edge : backEdges) {
        int tail = edge.first;
        int header = edge.second;

        auto loop = std::make_unique<Loop>(header);

        // Encontrar bloques del natural loop mediante BFS
        std::set<int> loopBlocks;
        loopBlocks.insert(header);

        if (tail != header) {
            loopBlocks.insert(tail);

            // BFS desde tail hacia header
            std::vector<int> worklist = {tail};
            std::set<int> visitedLocal;

            while (!worklist.empty()) {
                int current = worklist.back();
                worklist.pop_back();

                if (visitedLocal.find(current) != visitedLocal.end()) continue;
                visitedLocal.insert(current);

                // Agregar predecesores
                const auto& blocks = cfg.getBlocks();
                for (const auto& block : blocks) {
                    if (block->getId() == current) {
                        for (int pred : block->getPredecessors()) {
                            if (pred != header && visitedLocal.find(pred) == visitedLocal.end()) {
                                loopBlocks.insert(pred);
                                worklist.push_back(pred);
                            }
                        }
                        break;
                    }
                }
            }
        }

        // Agregar bloques al loop
        for (int blockId : loopBlocks) {
            loop->addBodyBlock(blockId);

            if (blockToLoop.find(blockId) == blockToLoop.end()) {
                blockToLoop[blockId] = loops.size();
            }
        }

        Logger::debug("Loop @ BB" + std::to_string(header) +
        " tiene " + std::to_string(loopBlocks.size()) + " bloques");

        loops.push_back(std::move(loop));
    }

    // Analizar cada loop detectado
    for (auto& loop : loops) {
        analyzeLoop(loop.get());
    }

    Logger::info("Loops detectados: " + std::to_string(loops.size()));
}

// Encuentra back-edges del CFG mediante DFS
// Output: vector de pares (tail, header) representando back-edges
void LoopDetector::findBackEdges(std::vector<std::pair<int, int>>& backEdges) {
    visited.clear();
    inStack.clear();

    const auto& blocks = cfg.getBlocks();
    if (!blocks.empty()) {
        dfsBackEdge(0, backEdges); // Empezar desde BB0
    }
}

// DFS recursivo para detectar back-edges
// Un back-edge ocurre cuando un nodo apunta a un ancestro en el stack
void LoopDetector::dfsBackEdge(int blockId, std::vector<std::pair<int, int>>& backEdges) {
    visited.insert(blockId);
    inStack.insert(blockId);

    const auto& blocks = cfg.getBlocks();
    const BasicBlock* block = blocks[blockId].get();

    for (int succ : block->getSuccessors()) {
        if (visited.find(succ) == visited.end()) {
            dfsBackEdge(succ, backEdges);
        } else if (inStack.find(succ) != inStack.end()) {
            backEdges.push_back({blockId, succ});
            blocks[succ]->setLoopHeader(true);

            Logger::debug("Back-edge: BB" + std::to_string(blockId) +
            " -> BB" + std::to_string(succ));
        }
    }

    inStack.erase(blockId);
}

// Analiza un loop contando instrucciones y branches
void LoopDetector::analyzeLoop(Loop* loop) {
    const auto& blocks = cfg.getBlocks();
    const auto& bodyBlocks = loop->getBodyBlocks();

    int branchCount = 0;
    int totalInstructions = 0;

    for (int blockId : bodyBlocks) {
        const BasicBlock* block = blocks[blockId].get();
        const auto& instructions = block->getInstructions();

        totalInstructions += instructions.size();

        for (const auto& instr : instructions) {
            if (instr.isBranchOperation()) {
                branchCount++;
            }
        }
    }

    Logger::debug("Loop @ BB" + std::to_string(loop->getHeaderId()) +
    ": " + std::to_string(totalInstructions) + " instrs, " +
    std::to_string(branchCount) + " branches (total en cuerpo)");

    // Clasificar complejidad
    classifyComplexity(loop);
}

void LoopDetector::classifyComplexity(Loop* loop) {
    const auto& blocks = cfg.getBlocks();
    const auto& bodyBlocks = loop->getBodyBlocks();

    int branchCount = 0;
    int internalBranches = 0;

    // Información para detectar patrón de loop contable
    struct InductionInfo {
        std::string var;
        bool hasIncrement = false;
        int incrementValue = 1;
        bool hasBound = false;
        bool boundIsConstant = false;
        int constantBound = -1;
        std::string boundRegister = "";
    };

    std::map<std::string, InductionInfo> inductionVars;

    int currentLoopId = -1;
    for (size_t i = 0; i < loops.size(); i++) {
        if (loops[i].get() == loop) {
            currentLoopId = i;
            break;
        }
    }

    std::set<int> innerLoopBlocks;
    for (size_t i = 0; i < loops.size(); i++) {
        if ((int)i != currentLoopId) {
            int otherHeader = loops[i]->getHeaderId();
            if (std::find(bodyBlocks.begin(), bodyBlocks.end(), otherHeader) != bodyBlocks.end()) {
                const auto& innerBodyBlocks = loops[i]->getBodyBlocks();
                for (int innerBlock : innerBodyBlocks) {
                    innerLoopBlocks.insert(innerBlock);
                }
            }
        }
    }

    for (int blockId : bodyBlocks) {
        if (innerLoopBlocks.find(blockId) != innerLoopBlocks.end()) {
            continue;
        }

        const BasicBlock* block = blocks[blockId].get();
        const auto& instructions = block->getInstructions();

        for (size_t i = 0; i < instructions.size(); i++) {
            const auto& instr = instructions[i];

            if (instr.isBranchOperation()) {
                // Ignorar branches incondicionales (pseudo-jumps)
                bool isUnconditionalJump = (instr.getOpcode() == "beq" &&
                instr.getRs1() == "zero" &&
                instr.getRs2() == "zero");

                if (isUnconditionalJump) {
                    Logger::debug("  Branch incondicional ignorado (pseudo-jump)");
                    continue; // No contar este branch
                }

                branchCount++;

                bool isLastInBlock = (i == instructions.size() - 1);
                bool isLoopExit = false;

                if (isLastInBlock) {
                    for (int succ : block->getSuccessors()) {
                        if (std::find(bodyBlocks.begin(), bodyBlocks.end(), succ) == bodyBlocks.end()) {
                            isLoopExit = true;
                            break;
                        }
                    }
                }

                if (!isLoopExit && !isLastInBlock) {
                    internalBranches++;
                }
            }

            // Patron: addi var, var, N (incremento de variable de induccion)
            if (instr.getOpcode() == "addi" &&
                instr.getRd() == instr.getRs1() &&
                instr.getImmediate() != 0) {

                std::string var = instr.getRd();
            inductionVars[var].var = var;
            inductionVars[var].hasIncrement = true;
            inductionVars[var].incrementValue = instr.getImmediate();

            Logger::debug("  Induction variable: " + var + " += " +
            std::to_string(instr.getImmediate()));
                }

                // Patron: addi tX, zero, N (carga de constante para bound)
                if (instr.getOpcode() == "addi" &&
                    instr.getRs1() == "zero" &&
                    instr.getImmediate() > 0) {

                    std::string tempReg = instr.getRd();
                int constantValue = instr.getImmediate();

                // Buscar slt que use este registro
                if (i + 1 < instructions.size()) {
                    const auto& nextInstr = instructions[i + 1];

                    if ((nextInstr.getOpcode() == "slt" ||
                        nextInstr.getOpcode() == "sltu") &&
                        nextInstr.getRs2() == tempReg) {

                        std::string inductVar = nextInstr.getRs1();
                    inductionVars[inductVar].hasBound = true;
                    inductionVars[inductVar].boundIsConstant = true;
                    inductionVars[inductVar].constantBound = constantValue;

                    Logger::debug("  Bound: " + inductVar + " < " +
                    std::to_string(constantValue));
                        }
                }
                    }

                    // Patron: slt (comparacion con bound en registro)
                    if (instr.getOpcode() == "slt" || instr.getOpcode() == "sltu") {
                        std::string var = instr.getRs1();
                        std::string boundReg = instr.getRs2();

                        // Si var es una induction variable conocida
                        if (inductionVars.find(var) != inductionVars.end()) {
                            inductionVars[var].hasBound = true;
                            inductionVars[var].boundIsConstant = false;
                            inductionVars[var].boundRegister = boundReg;

                            Logger::debug("  Bound: " + var + " < " + boundReg + " (runtime)");
                        }
                    }
        }
    }

    // Evaluar si el loop es countable
    bool isCountable = false;
    int tripCount = -1;

    for (const auto& pair : inductionVars) {
        const InductionInfo& info = pair.second;

        if (info.hasIncrement && info.hasBound) {
            isCountable = true;

            if (info.boundIsConstant) {
                tripCount = info.constantBound / info.incrementValue;
                Logger::debug("  Loop countable: " + info.var +
                " itera ~" + std::to_string(tripCount) + " veces");
            } else {
                tripCount = -1;
                Logger::debug("  Loop countable: " + info.var +
                " bound dinámico (" + info.boundRegister + ")");
            }

            break;
        }
    }

    Logger::debug("Loop @ BB" + std::to_string(loop->getHeaderId()) +
    " - Branches: " + std::to_string(branchCount) +
    ", Internal: " + std::to_string(internalBranches) +
    ", Countable: " + std::to_string(isCountable) +
    ", TripCount: " + std::to_string(tripCount));

    if (internalBranches > 1) {
        loop->setComplexity(LoopComplexity::COMPLEX);
        loop->setCountable(false);
    }
    else if (internalBranches == 1) {
        loop->setComplexity(LoopComplexity::MODERATE);
        loop->setCountable(isCountable);
        loop->setTripCount(tripCount);
    }
    else if (branchCount == 0) {
        loop->setComplexity(LoopComplexity::COMPLEX);
        loop->setCountable(false);
    }
    else if (branchCount == 1) {
        loop->setComplexity(LoopComplexity::SIMPLE);
        loop->setCountable(isCountable);
        loop->setTripCount(tripCount);
    }
    else {
        loop->setComplexity(LoopComplexity::MODERATE);
        loop->setCountable(isCountable);
        loop->setTripCount(tripCount);
    }
}

void LoopDetector::printLoops() const {
    Logger::info("=== LOOPS DETECTADOS ===");
    for (const auto& loop : loops) {
        std::cout << loop->toString() << std::endl;
    }
}

// Guarda informacion de loops en un archivo
// Input: nombre del archivo de salida
// Output: true si tuvo exito
bool LoopDetector::saveLoopsToFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return false;
    }

    file << "# Loops Detectados\n";
    file << "# Total: " << loops.size() << "\n\n";

    for (size_t i = 0; i < loops.size(); i++) {
        file << "=== LOOP " << i << " ===\n";
        file << loops[i]->toString() << "\n";
    }

    file.close();
    Logger::info("Loops guardados en: " + filename);
    return true;
}
