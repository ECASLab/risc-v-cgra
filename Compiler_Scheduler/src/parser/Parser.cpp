#include "Parser.h"
#include "../utils/Logger.h"
#include <fstream>

// Constructor: inicializa parser con referencia a lexer
// Input: lex (referencia a Lexer)
// Output: instancia de Parser
Parser::Parser(Lexer& lex) : lexer(lex) {}

// Parsea todas las líneas del lexer y extrae instrucciones y labels
// Input: ninguno (usa lexer interno)
// Output: true si parsing exitoso, almacena instrucciones y labels
bool Parser::parse() {
    Logger::info("Iniciando parsing...");

    const auto& lines = lexer.getLines();
    int instrIndex = 0;

    for (size_t i = 0; i < lines.size(); i++) {
        Instruction instr(lines[i], i + 1);

        if (instr.getIsLabel()) {
            labels[instr.getLabelName()] = instrIndex;
            Logger::debug("Label encontrado: " + instr.getLabelName() + " @ index " + std::to_string(instrIndex));
        } else if (instr.getType() != InstructionType::UNKNOWN &&
            instr.getType() != InstructionType::DIRECTIVE) {
            instructions.push_back(instr);
        instrIndex++;
            }
    }

    Logger::info("Parsing completado: " + std::to_string(instructions.size()) + " instrucciones");
    Logger::info("Labels encontrados: " + std::to_string(labels.size()));

    return true;
}

// Resuelve referencias a labels en branches y jumps
// Input: ninguno (usa instructions y labels internos)
// Output: verifica que todos los labels existan
void Parser::resolveLabels() {
    Logger::info("Resolviendo referencias a labels...");

    for (auto& instr : instructions) {
        if (instr.isBranchOperation() || instr.isJumpOperation()) {
            std::string targetLabel = instr.getLabel();
            if (!targetLabel.empty() && labels.find(targetLabel) != labels.end()) {
                Logger::debug("Resuelto: " + targetLabel + " -> " + std::to_string(labels[targetLabel]));
            } else if (!targetLabel.empty()) {
                Logger::warning("Label no encontrado: " + targetLabel);
            }
        }
    }
}

// Imprime todas las instrucciones parseadas a consola
void Parser::printInstructions() const {
    Logger::info("=== INSTRUCCIONES PARSEADAS ===");
    for (const auto& instr : instructions) {
        std::cout << instr.toString() << std::endl;
    }
}

// Imprime todos los labels encontrados a consola
void Parser::printLabels() const {
    Logger::info("=== LABELS ===");
    for (const auto& pair : labels) {
        std::cout << pair.first << " -> instrucción #" << pair.second << std::endl;
    }
}

// Guarda instrucciones y labels en archivo de texto
// Input: filename (ruta del archivo)
// Output: true si guardado exitoso, false si falla
bool Parser::saveToFile(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo crear archivo: " + filename);
        return false;
    }

    file << "# Instrucciones parseadas: " << instructions.size() << "\n\n";

    for (size_t i = 0; i < instructions.size(); i++) {
        file << "[" << i << "] " << instructions[i].toString() << "\n";
    }

    file << "\n# Labels encontrados: " << labels.size() << "\n";
    for (const auto& pair : labels) {
        file << pair.first << " @ instrucción " << pair.second << "\n";
    }

    file.close();
    Logger::info("Resultados guardados en: " + filename);
    return true;
}
