#include "CriticalPath.h"
#include "../utils/Logger.h"
#include <fstream>
#include <algorithm>
#include <queue>
#include <functional>

// Constructor
// Input: referencia al DFG construido
CriticalPath::CriticalPath(DFGBuilder& dfg)
: dfgBuilder(dfg), criticalPathLength(0), averageParallelism(0.0) {}

// Realiza el analisis completo del camino critico
// Calcula ASAP, ALAP, identifica nodos criticos y paralelismo
// Output: actualiza criticalPathLength y averageParallelism
void CriticalPath::analyze() {
    Logger::info("Analizando camino crítico...");

    computeASAP();
    computeALAP();
    identifyCriticalPath();
    computeParallelism();

    Logger::info("Longitud del camino crítico: " + std::to_string(criticalPathLength) + " ciclos");
    Logger::info("Paralelismo promedio: " + std::to_string(averageParallelism));
}

// Calcula tiempos de inicio mas tempranos (ASAP) usando ordenamiento topologico
// Propaga tiempos de inicio desde nodos raiz hacia adelante
// Output: actualiza earliestStartTime de cada nodo del DFG
void CriticalPath::computeASAP() {
    Logger::debug("Calculando ASAP (Earliest Start Times)...");

    // Topological sort usando BFS
    std::queue<int> queue;
    std::map<int, int> inDegree;

    // Inicializar grados de entrada
    for (const auto& node : dfgBuilder.getNodes()) {
        inDegree[node->getId()] = node->getPredecessors().size();

        if (inDegree[node->getId()] == 0) {
            queue.push(node->getId());
            dfgBuilder.getNode(node->getId())->setEarliestStartTime(0);
        }
    }

    // BFS
    while (!queue.empty()) {
        int nodeId = queue.front();
        queue.pop();

        DFGNode* node = dfgBuilder.getNode(nodeId);
        int finishTime = node->getEarliestStartTime() + node->getLatency();

        // Propagar a sucesores
        for (int succId : node->getSuccessors()) {
            DFGNode* succ = dfgBuilder.getNode(succId);

            // El sucesor no puede empezar hasta que termine el predecesor
            int newStart = finishTime;
            if (newStart > succ->getEarliestStartTime()) {
                succ->setEarliestStartTime(newStart);
            }

            inDegree[succId]--;
            if (inDegree[succId] == 0) {
                queue.push(succId);
            }
        }
    }
}

// Calcula tiempos de inicio mas tardios (ALAP) retropropagando desde el makespan
// Determina la flexibilidad temporal de cada operacion (slack)
// Output: actualiza latestStartTime y slack de cada nodo
void CriticalPath::computeALAP() {
    Logger::debug("Calculando ALAP (Latest Start Times)...");

    // Encontrar el makespan (tiempo de finalización máximo)
    int makespan = 0;
    for (const auto& node : dfgBuilder.getNodes()) {
        int finishTime = node->getEarliestStartTime() + node->getLatency();
        if (finishTime > makespan) {
            makespan = finishTime;
        }
    }

    criticalPathLength = makespan;

    // Inicializar nodos hoja con makespan - latency
    for (int leafId : dfgBuilder.getLeafNodes()) {
        DFGNode* leaf = dfgBuilder.getNode(leafId);
        leaf->setLatestStartTime(makespan - leaf->getLatency());
    }

    // Retropropagación usando topological sort inverso
    std::queue<int> queue;
    std::map<int, int> outDegree;

    for (const auto& node : dfgBuilder.getNodes()) {
        outDegree[node->getId()] = node->getSuccessors().size();

        if (outDegree[node->getId()] == 0) {
            queue.push(node->getId());
        }
    }

    while (!queue.empty()) {
        int nodeId = queue.front();
        queue.pop();

        DFGNode* node = dfgBuilder.getNode(nodeId);

        // Propagar a predecesores
        for (int predId : node->getPredecessors()) {
            DFGNode* pred = dfgBuilder.getNode(predId);

            // El predecesor debe terminar antes de que empiece el sucesor
            int latestFinish = node->getLatestStartTime();
            int newLatestStart = latestFinish - pred->getLatency();

            // Tomar el mínimo (más restrictivo)
            if (pred->getLatestStartTime() == 0 ||
                newLatestStart < pred->getLatestStartTime()) {
                pred->setLatestStartTime(newLatestStart);
                }

                outDegree[predId]--;
            if (outDegree[predId] == 0) {
                queue.push(predId);
            }
        }
    }

    // Calcular slack
    for (auto& node : dfgBuilder.getNodes()) {
        int slack = node->getLatestStartTime() - node->getEarliestStartTime();
        node->setSlack(slack);
    }
}

// Identifica los nodos que pertenecen al camino critico (slack = 0)
// Realiza traceback desde el nodo final hacia atras
// Output: llena criticalPathNodes con IDs de nodos criticos
void CriticalPath::identifyCriticalPath() {
    Logger::debug("Identificando nodos en el camino crítico...");

    criticalPathNodes.clear();

    int maxEndTime = 0;
    DFGNode* finalNode = nullptr;

    for (auto& node : dfgBuilder.getNodes()) {
        int endTime = node->getEarliestStartTime() + node->getLatency();
        if (endTime > maxEndTime) {
            maxEndTime = endTime;
            finalNode = node.get();
        }
    }

    if (!finalNode) {
        Logger::warning("No se encontró nodo final para traceback");
        return;
    }

    Logger::debug("Nodo final encontrado: Node " + std::to_string(finalNode->getId()) +
    " (finish=" + std::to_string(maxEndTime) + ")");

    std::set<int> visited;
    std::function<void(DFGNode*)> traceback = [&](DFGNode* node) {
        if (!node || visited.count(node->getId())) return;

        if (node->getSlack() == 0) {
            visited.insert(node->getId());
            criticalPathNodes.push_back(node->getId());
            node->setIsOnCriticalPath(true);

            // Buscar el predecesor en camino critico (desempate: tomar el primero)
            bool foundPredecessor = false;
            for (int predId : node->getPredecessors()) {
                if (foundPredecessor) break;

                DFGNode* pred = dfgBuilder.getNode(predId);
                if (pred && pred->getSlack() == 0) {
                    int predFinish = pred->getEarliestStartTime() + pred->getLatency();
                    if (predFinish == node->getEarliestStartTime()) {
                        traceback(pred);
                        foundPredecessor = true;
                    }
                }
            }
        }
    };

    traceback(finalNode);
    std::reverse(criticalPathNodes.begin(), criticalPathNodes.end());

    Logger::debug("Nodos en camino crítico: " + std::to_string(criticalPathNodes.size()));
}

// Calcula el paralelismo promedio (ILP) del codigo
// Formula: ILP = Total de operaciones / Longitud del camino critico
// Output: actualiza averageParallelism
void CriticalPath::computeParallelism() {
    Logger::debug("Calculando paralelismo promedio...");

    if (criticalPathLength == 0) {
        averageParallelism = 0.0;
        return;
    }

    // ILP = Total operations / Critical path length
    int totalOps = dfgBuilder.getNodes().size();
    averageParallelism = (double)totalOps / (double)criticalPathLength;
}

// Imprime el analisis del camino critico en consola
// Output: muestra longitud, nodos criticos y paralelismo
void CriticalPath::printAnalysis() const {
    Logger::info("=== ANÁLISIS DE CAMINO CRÍTICO ===");

    std::cout << "Longitud del camino crítico: " << criticalPathLength << " ciclos\n";
    std::cout << "Nodos en camino crítico: " << criticalPathNodes.size() << "\n";
    std::cout << "Paralelismo promedio (ILP): " << averageParallelism << "\n\n";

    std::cout << "Nodos críticos:\n";
    for (int nodeId : criticalPathNodes) {
        const DFGNode* node = dfgBuilder.getNode(nodeId);
        std::cout << "  Node " << nodeId << ": "
        << node->getInstruction().getOpcode() << "\n";
    }
}

// Guarda el analisis del camino critico en un archivo
// Input: nombre del archivo de salida
// Output: archivo con resultados del analisis, retorna true si tuvo exito
bool CriticalPath::saveAnalysisToFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return false;
    }

    file << "# Critical Path Analysis\n\n";
    file << "Critical Path Length: " << criticalPathLength << " cycles\n";
    file << "Nodes on Critical Path: " << criticalPathNodes.size() << "\n";
    file << "Average Parallelism (ILP): " << averageParallelism << "\n\n";

    file << "## Critical Path Nodes:\n";
    for (int nodeId : criticalPathNodes) {
        const DFGNode* node = dfgBuilder.getNode(nodeId);
        file << "Node " << nodeId << " [Instr " << node->getInstructionIndex() << "]: "
        << node->getInstruction().getOpcode() << "\n";
        file << "  EST: " << node->getEarliestStartTime()
        << ", LST: " << node->getLatestStartTime()
        << ", Slack: " << node->getSlack() << "\n";
    }

    file.close();
    Logger::info("Análisis guardado en: " + filename);
    return true;
}
