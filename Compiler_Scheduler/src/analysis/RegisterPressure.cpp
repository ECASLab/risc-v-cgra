#include "RegisterPressure.h"
#include "../utils/Logger.h"
#include <fstream>
#include <algorithm>

// Constructor
// Input: DFG construido, parser con instrucciones, configuracion de hardware
RegisterPressure::RegisterPressure(const DFGBuilder& dfg, const Parser& p, const ConfigReader& cfg)
: dfgBuilder(dfg), parser(p), config(cfg), maxPressure(0), avgPressure(0),
needsSpilling(false) {
    numRegistersAvailable = config.getNumRegisters();
}

// Realiza el analisis completo de presion de registros
// Calcula live ranges, presion temporal y necesidad de spilling
// Output: actualiza maxPressure, avgPressure y needsSpilling
void RegisterPressure::analyze() {
    Logger::info("Analizando presión de registros...");

    computeLiveRanges();
    computePressureAtEachTime();
    evaluateSpillingNeed();

    Logger::info("Presión máxima de registros: " + std::to_string(maxPressure) +
    " / " + std::to_string(numRegistersAvailable));

    if (needsSpilling) {
        Logger::warning("Se requiere spilling: presión excede registros disponibles");
    }
}

// Calcula los rangos de vida de cada registro
// Determina cuando nace (primera escritura) y muere (ultimo uso) cada registro
// Output: llena el vector liveRanges con informacion de cada registro
void RegisterPressure::computeLiveRanges() {
    Logger::debug("Calculando live ranges...");

    std::map<std::string, int> firstDef;   // register -> first write time
    std::map<std::string, int> lastUse;    // register -> last read time

    const auto& nodes = dfgBuilder.getNodes();

    // Identificar todos los registros usados y sus accesos
    for (const auto& node : nodes) {
        const Instruction& instr = node->getInstruction();
        int time = node->getEarliestStartTime();

        // Registrar lecturas (uses)
        if (!instr.getRs1().empty() && instr.getRs1() != "zero") {
            lastUse[instr.getRs1()] = time;
            // Si este registro nunca fue definido, es un argumento de entrada
            if (firstDef.find(instr.getRs1()) == firstDef.end()) {
                firstDef[instr.getRs1()] = 0;  // Vivo desde el inicio
            }
        }
        if (!instr.getRs2().empty() && instr.getRs2() != "zero") {
            lastUse[instr.getRs2()] = time;
            if (firstDef.find(instr.getRs2()) == firstDef.end()) {
                firstDef[instr.getRs2()] = 0;
            }
        }

        // Registrar escritura (def)
        if (!instr.getRd().empty() && instr.getRd() != "zero") {
            if (firstDef.find(instr.getRd()) == firstDef.end()) {
                firstDef[instr.getRd()] = time;
            }
            // Actualizar lastUse si este registro también se usa después
            // (no lo hacemos aquí, se maneja en el paso anterior)
        }
    }

    // Crear live ranges basados en tiempos de definicion y uso
    liveRanges.clear();
    for (const auto& pair : firstDef) {
        std::string reg = pair.first;
        int birth = pair.second;

        // Si el registro nunca se lee después de ser definido, muere inmediatamente
        int death = (lastUse.find(reg) != lastUse.end()) ? lastUse[reg] : birth;

        if (death >= birth) {
            liveRanges.emplace_back(reg, birth, death);
        }
    }

    Logger::debug("Live ranges calculados: " + std::to_string(liveRanges.size()));
}

// Calcula cuantos registros estan vivos en cada instante de tiempo
// Output: actualiza liveAtTime, maxPressure y avgPressure
void RegisterPressure::computePressureAtEachTime() {
    Logger::debug("Calculando presión en cada tiempo...");

    liveAtTime.clear();

    // Para cada live range, marcar los tiempos en los que está vivo
    for (const auto& lr : liveRanges) {
        for (int t = lr.birthTime; t <= lr.deathTime; t++) {
            liveAtTime[t].insert(lr.registerName);
        }
    }

    // Calcular presión máxima y promedio
    maxPressure = 0;
    int totalPressure = 0;
    int numTimePoints = 0;

    for (const auto& pair : liveAtTime) {
        int pressure = pair.second.size();

        if (pressure > maxPressure) {
            maxPressure = pressure;
        }

        totalPressure += pressure;
        numTimePoints++;
    }

    if (numTimePoints > 0) {
        avgPressure = totalPressure / numTimePoints;
    }

    Logger::debug("Presión máxima: " + std::to_string(maxPressure));
    Logger::debug("Presión promedio: " + std::to_string(avgPressure));
}

// Evalua si se necesita spilling comparando presion con registros disponibles
// Output: actualiza needsSpilling
void RegisterPressure::evaluateSpillingNeed() {
    needsSpilling = (maxPressure > numRegistersAvailable);

    if (needsSpilling) {
        int spillCount = maxPressure - numRegistersAvailable;
        Logger::warning("Spilling requerido: " + std::to_string(spillCount) +
        " registros deben ir a memoria");
    }
}

// Imprime el analisis de presion de registros en consola
// Output: muestra presion maxima, promedio y necesidad de spilling
void RegisterPressure::printAnalysis() const {
    Logger::info("=== ANÁLISIS DE PRESIÓN DE REGISTROS ===");

    std::cout << "Registros disponibles: " << numRegistersAvailable << "\n";
    std::cout << "Presión máxima: " << maxPressure << "\n";
    std::cout << "Presión promedio: " << avgPressure << "\n";
    std::cout << "Spilling requerido: " << (needsSpilling ? "SÍ" : "NO") << "\n\n";

    if (needsSpilling) {
        std::cout << "ADVERTENCIA: Se requiere spilling de "
        << (maxPressure - numRegistersAvailable) << " registros\n\n";
    }

    std::cout << "Live Ranges (top 10 más largos):\n";

    // Copiar y ordenar por longitud
    std::vector<LiveRange> sorted = liveRanges;
    std::sort(sorted.begin(), sorted.end(),
              [](const LiveRange& a, const LiveRange& b) {
                  return a.length > b.length;
              });

    int count = 0;
    for (const auto& lr : sorted) {
        if (count++ >= 10) break;
        std::cout << "  " << lr.registerName
        << ": [" << lr.birthTime << " - " << lr.deathTime
        << "] length=" << lr.length << "\n";
    }
}

// Guarda el analisis de presion de registros en un archivo
// Input: nombre del archivo de salida
// Output: archivo con live ranges y presion temporal, retorna true si tuvo exito
bool RegisterPressure::saveAnalysisToFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return false;
    }

    file << "# Register Pressure Analysis\n\n";
    file << "Available Registers: " << numRegistersAvailable << "\n";
    file << "Maximum Pressure: " << maxPressure << "\n";
    file << "Average Pressure: " << avgPressure << "\n";
    file << "Spilling Required: " << (needsSpilling ? "YES" : "NO") << "\n\n";

    if (needsSpilling) {
        file << "WARNING: Spilling needed for "
        << (maxPressure - numRegistersAvailable) << " registers\n\n";
    }

    file << "## Live Ranges:\n";
    for (const auto& lr : liveRanges) {
        file << lr.registerName << ": [" << lr.birthTime << " - "
        << lr.deathTime << "] length=" << lr.length << "\n";
    }

    file << "\n## Pressure at Each Time:\n";
    for (const auto& pair : liveAtTime) {
        file << "Time " << pair.first << ": " << pair.second.size() << " registers live (";
        bool first = true;
        for (const auto& reg : pair.second) {
            if (!first) file << ", ";
            file << reg;
            first = false;
        }
        file << ")\n";
    }

    file.close();
    Logger::info("Análisis guardado en: " + filename);
    return true;
}
