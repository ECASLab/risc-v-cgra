#include "ConfigReader.h"
#include "../utils/Logger.h"
#include <fstream>
#include <sstream>

// Constructor
// Inicializa latencias y configuracion de hardware por defecto
ConfigReader::ConfigReader() {
    setDefaultLatencies();
    setDefaultHardware();
}

// Establece las latencias por defecto para cada tipo de operacion
// Basado en la arquitectura CGRA definida en la tesis
void ConfigReader::setDefaultLatencies() {
    // ALU operations - 2 estados (lectura + ejecución + escritura)
    latencies["add"] = 2;
    latencies["sub"] = 2;
    latencies["and"] = 2;
    latencies["or"] = 2;
    latencies["xor"] = 2;
    latencies["sll"] = 2;
    latencies["srl"] = 2;
    latencies["sra"] = 2;
    latencies["slt"] = 2;
    latencies["sltu"] = 2;

    // ALU immediate
    latencies["addi"] = 2;
    latencies["andi"] = 2;
    latencies["ori"] = 2;
    latencies["xori"] = 2;
    latencies["slli"] = 2;
    latencies["srli"] = 2;
    latencies["srai"] = 2;
    latencies["slti"] = 2;
    latencies["sltiu"] = 2;

    // Multiply - más ciclos
    latencies["mul"] = 4;

    // Load operations - 3 estados
    latencies["lw"] = 3;
    latencies["lh"] = 3;
    latencies["lb"] = 3;
    latencies["lbu"] = 3;
    latencies["lhu"] = 3;

    // Store operations - 5 estados
    latencies["sw"] = 5;
    latencies["sh"] = 5;
    latencies["sb"] = 5;

    // Branch/Jump - 3 estados
    latencies["beq"] = 3;
    latencies["bne"] = 3;
    latencies["blt"] = 3;
    latencies["bge"] = 3;
    latencies["jal"] = 3;

    // Special
    latencies["lui"] = 1;
}

// Establece la configuracion de hardware por defecto
void ConfigReader::setDefaultHardware() {
    numPEs = 4;
    numRegisters = 32;
    memoryBanks = 4;
    topology = "mesh2d";

    // Configuracion del arbitro
    arbiterPolicy = "round_robin";
    arbiterGrantLatency = 1;
    arbiterContentionPenalty = 1;
}

// Carga configuracion de latencias desde un archivo YAML
// Input: ruta del archivo de configuracion
// Output: true si cargo exitosamente, false si usa valores por defecto
bool ConfigReader::loadLatencyConfig(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        Logger::warning("No se pudo abrir archivo de latencias: " + filename);
        Logger::info("Usando latencias por defecto");
        return false;
    }

    // Parsing simple de archivo YAML
    // Formato esperado: "opcode: latency"
    std::string line;
    while (std::getline(file, line)) {
        // Ignorar comentarios y líneas vacías
        if (line.empty() || line[0] == '#') continue;

        // Buscar líneas con formato "key: value"
        size_t colonPos = line.find(':');
        if (colonPos != std::string::npos) {
            std::string key = line.substr(0, colonPos);
            std::string value = line.substr(colonPos + 1);

            // Trim whitespace
            key.erase(0, key.find_first_not_of(" \t"));
            key.erase(key.find_last_not_of(" \t") + 1);
            value.erase(0, value.find_first_not_of(" \t"));
            value.erase(value.find_last_not_of(" \t") + 1);

            // Convertir valor a int
            try {
                int latency = std::stoi(value);
                latencies[key] = latency;
            } catch (...) {
                // Ignorar líneas que no sean números
            }
        }
    }

    file.close();
    Logger::info("Configuración de latencias cargada desde: " + filename);
    return true;
}

// Carga configuracion de hardware desde un archivo YAML
// Input: ruta del archivo de configuracion
// Output: true si cargo exitosamente, false si usa valores por defecto
bool ConfigReader::loadHardwareConfig(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        Logger::warning("No se pudo abrir archivo de hardware: " + filename);
        Logger::info("Usando configuración de hardware por defecto");
        return false;
    }

    // Parsing simple (similar a latencias)
    std::string line;
    while (std::getline(file, line)) {
        if (line.empty() || line[0] == '#') continue;

        size_t colonPos = line.find(':');
        if (colonPos != std::string::npos) {
            std::string key = line.substr(0, colonPos);
            std::string value = line.substr(colonPos + 1);

            key.erase(0, key.find_first_not_of(" \t"));
            key.erase(key.find_last_not_of(" \t") + 1);
            value.erase(0, value.find_first_not_of(" \t"));
            value.erase(value.find_last_not_of(" \t") + 1);

            if (key == "num_pes") {
                numPEs = std::stoi(value);
            } else if (key == "total_registers") {
                numRegisters = std::stoi(value);
            } else if (key == "num_banks") {
                memoryBanks = std::stoi(value);
            } else if (key == "topology") {
                topology = value;
            }
        }
    }

    file.close();
    Logger::info("Configuración de hardware cargada desde: " + filename);
    return true;
}

// Obtiene la latencia de una operacion especifica
// Input: opcode de la operacion
// Output: latencia en ciclos (retorna 1 si no se encuentra)
int ConfigReader::getLatency(const std::string& opcode) const {
    auto it = latencies.find(opcode);
    if (it != latencies.end()) {
        return it->second;
    }

    Logger::warning("Latencia desconocida para: " + opcode + ", usando 1");
    return 1;
}
