#include "DependencyAnalyzer.h"
#include "../utils/Logger.h"
#include <fstream>

// Constructor
// Input: parser con instrucciones, detector de loops
DependencyAnalyzer::DependencyAnalyzer(const Parser& p, const LoopDetector& ld)
: parser(p), loopDetector(ld) {}

// Realiza el analisis completo de dependencias
// Detecta dependencias RAW, WAR, WAW y de memoria
void DependencyAnalyzer::analyze() {
    Logger::info("Analizando dependencias...");

    analyzeRAW();
    analyzeWAR();
    analyzeWAW();
    analyzeMemoryDependencies();

    Logger::info("Dependencias detectadas: " + std::to_string(dependencies.size()));
}

// Analiza dependencias RAW (Read After Write)
// Detecta cuando una instruccion lee un registro escrito por una instruccion previa
void DependencyAnalyzer::analyzeRAW() {
    Logger::debug("Analizando dependencias RAW (Read After Write)...");

    const auto& instructions = parser.getInstructions();
    lastWriter.clear();

    for (size_t i = 0; i < instructions.size(); i++) {
        const auto& instr = instructions[i];

        // Verificar si lee registros que fueron escritos antes
        if (!instr.getRs1().empty() && instr.getRs1() != "zero") {
            if (lastWriter.find(instr.getRs1()) != lastWriter.end()) {
                int writerIndex = lastWriter[instr.getRs1()];
                addDependency(writerIndex, i, DependencyType::RAW, instr.getRs1());
            }
        }

        if (!instr.getRs2().empty() && instr.getRs2() != "zero") {
            if (lastWriter.find(instr.getRs2()) != lastWriter.end()) {
                int writerIndex = lastWriter[instr.getRs2()];
                addDependency(writerIndex, i, DependencyType::RAW, instr.getRs2());
            }
        }

        // Actualizar último escritor si esta instrucción escribe
        if (!instr.getRd().empty() && instr.getRd() != "zero") {
            lastWriter[instr.getRd()] = i;
        }
    }
}

// Analiza dependencias WAR (Write After Read)
// Detecta cuando una instruccion escribe un registro leido por una instruccion previa
void DependencyAnalyzer::analyzeWAR() {
    Logger::debug("Analizando dependencias WAR (Write After Read)...");

    const auto& instructions = parser.getInstructions();
    readers.clear();

    for (size_t i = 0; i < instructions.size(); i++) {
        const auto& instr = instructions[i];

        // Si esta instrucción escribe a un registro
        if (!instr.getRd().empty() && instr.getRd() != "zero") {
            std::string reg = instr.getRd();

            // Verificar si hay lecturas previas de este registro
            if (readers.find(reg) != readers.end()) {
                for (int readerIndex : readers[reg]) {
                    if (readerIndex < (int)i) {
                        addDependency(readerIndex, i, DependencyType::WAR, reg);
                    }
                }
            }

            // Limpiar lista de lectores (ya no importan después de escribir)
            readers[reg].clear();
        }

        // Registrar lecturas
        if (!instr.getRs1().empty() && instr.getRs1() != "zero") {
            readers[instr.getRs1()].push_back(i);
        }
        if (!instr.getRs2().empty() && instr.getRs2() != "zero") {
            readers[instr.getRs2()].push_back(i);
        }
    }
}

// Analiza dependencias WAW (Write After Write)
// Detecta cuando dos instrucciones escriben al mismo registro
void DependencyAnalyzer::analyzeWAW() {
    Logger::debug("Analizando dependencias WAW (Write After Write)...");

    const auto& instructions = parser.getInstructions();
    std::map<std::string, int> lastWriterWAW;

    for (size_t i = 0; i < instructions.size(); i++) {
        const auto& instr = instructions[i];

        if (!instr.getRd().empty() && instr.getRd() != "zero") {
            std::string reg = instr.getRd();

            // Si ya había un escritor anterior
            if (lastWriterWAW.find(reg) != lastWriterWAW.end()) {
                int prevWriter = lastWriterWAW[reg];
                addDependency(prevWriter, i, DependencyType::WAW, reg);
            }

            lastWriterWAW[reg] = i;
        }
    }
}

// Analiza dependencias de memoria entre operaciones load y store
// Usa estrategia conservadora para garantizar correctitud
void DependencyAnalyzer::analyzeMemoryDependencies() {
    Logger::debug("Analizando dependencias de memoria...");

    const auto& instructions = parser.getInstructions();
    std::vector<int> loads;
    std::vector<int> stores;

    // Recolectar todas las operaciones de memoria
    for (size_t i = 0; i < instructions.size(); i++) {
        const auto& instr = instructions[i];

        if (instr.isLoadOperation()) {
            loads.push_back(i);
        } else if (instr.isStoreOperation()) {
            stores.push_back(i);
        }
    }

    // Estrategia conservadora:
    // Store -> Load: RAW de memoria (conservador: todos los loads posteriores)
    for (int storeIdx : stores) {
        for (int loadIdx : loads) {
            if (loadIdx > storeIdx) {
                addDependency(storeIdx, loadIdx, DependencyType::MEMORY, "memory");
            }
        }
    }

    // Store -> Store: serializar consecutivos (preservar orden de escrituras)
    for (size_t i = 0; i + 1 < stores.size(); i++) {
        addDependency(stores[i], stores[i + 1], DependencyType::MEMORY, "memory");
    }

    // Load -> Load: pueden ejecutarse en paralelo (no se crean dependencias)

    int memDeps = stores.size() * loads.size() + (stores.size() > 0 ? stores.size() - 1 : 0);
    Logger::debug("Dependencias de memoria creadas: " + std::to_string(memDeps));
}

// Agrega una nueva dependencia al grafo
// Input: indices de instrucciones origen y destino, tipo, recurso
void DependencyAnalyzer::addDependency(int src, int dst, DependencyType type,
                                       const std::string& resource) {
    auto dep = std::make_unique<Dependency>(src, dst, type, resource);
    dependencies.push_back(std::move(dep));

    // Actualizar grafo
    dependencyGraph[src].insert(dst);
}

// Imprime resumen de dependencias detectadas en consola
void DependencyAnalyzer::printDependencies() const {
    Logger::info("=== DEPENDENCIAS DETECTADAS ===");

                                           int rawCount = 0, warCount = 0, wawCount = 0, memCount = 0;

                                           for (const auto& dep : dependencies) {
                                               switch (dep->getType()) {
                                                   case DependencyType::RAW: rawCount++; break;
                                                   case DependencyType::WAR: warCount++; break;
                                                   case DependencyType::WAW: wawCount++; break;
                                                   case DependencyType::MEMORY: memCount++; break;
                                               }
                                           }

                                           std::cout << "Total: " << dependencies.size() << " dependencias\n";
                                           std::cout << "  RAW: " << rawCount << "\n";
                                           std::cout << "  WAR: " << warCount << "\n";
                                           std::cout << "  WAW: " << wawCount << "\n";
    std::cout << "  MEMORY: " << memCount << "\n";
}

// Guarda el analisis de dependencias en un archivo
// Input: nombre del archivo de salida
// Output: archivo con lista de dependencias, retorna true si tuvo exito
bool DependencyAnalyzer::saveDependenciesToFile(const std::string& filename) const {
    std::ofstream file(filename);
                                           if (!file.is_open()) {
                                               Logger::error("No se pudo crear archivo: " + filename);
                                               return false;
                                           }

                                           file << "# Dependency Analysis\n";
                                           file << "# Total dependencies: " << dependencies.size() << "\n\n";

                                           file << "## Dependencias por tipo:\n";
                                           int rawCount = 0, warCount = 0, wawCount = 0, memCount = 0;

                                           for (const auto& dep : dependencies) {
                                               switch (dep->getType()) {
                                                   case DependencyType::RAW: rawCount++; break;
                                                   case DependencyType::WAR: warCount++; break;
                                                   case DependencyType::WAW: wawCount++; break;
                                                   case DependencyType::MEMORY: memCount++; break;
                                               }
                                           }

                                           file << "RAW: " << rawCount << "\n";
                                           file << "WAR: " << warCount << "\n";
                                           file << "WAW: " << wawCount << "\n";
                                           file << "MEMORY: " << memCount << "\n\n";

                                           file << "## Lista de dependencias:\n";
                                           for (const auto& dep : dependencies) {
                                               file << dep->toString() << "\n";
                                           }

                                           file.close();
                                           Logger::info("Dependencias guardadas en: " + filename);
    return true;
}

// Guarda el grafo de dependencias en formato DOT para visualizacion
// Input: nombre del archivo .dot de salida
// Output: archivo DOT compatible con Graphviz, retorna true si tuvo exito
bool DependencyAnalyzer::saveDotFile(const std::string& filename) const {
    std::ofstream file(filename);
                                           if (!file.is_open()) {
                                               Logger::error("No se pudo crear archivo: " + filename);
                                               return false;
                                           }

                                           file << "digraph Dependencies {\n";
                                           file << "  rankdir=TB;\n";
                                           file << "  node [shape=box];\n\n";

                                           // Nodos
                                           const auto& instructions = parser.getInstructions();
                                           for (size_t i = 0; i < instructions.size(); i++) {
                                               file << "  I" << i << " [label=\"[" << i << "] "
                                               << instructions[i].getOpcode() << "\"];\n";
                                           }

                                           file << "\n";

                                           // Aristas
                                           for (const auto& dep : dependencies) {
                                               std::string color;
                                               switch (dep->getType()) {
                                                   case DependencyType::RAW: color = "red"; break;
                                                   case DependencyType::WAR: color = "blue"; break;
                                                   case DependencyType::WAW: color = "green"; break;
                                                   case DependencyType::MEMORY: color = "orange"; break;
                                               }

                                               file << "  I" << dep->getSource() << " -> I" << dep->getDest()
                                               << " [label=\"" << dep->typeToString() << "\", color=" << color << "];\n";
                                           }

                                           file << "}\n";
                                           file.close();

                                           Logger::info("Archivo DOT guardado: " + filename);
                                           return true;
                                       }
