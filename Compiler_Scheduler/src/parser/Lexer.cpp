#include "Lexer.h"
#include "../utils/Logger.h"

// Constructor: inicializa lexer con nombre de archivo a leer
// Input: file (ruta del archivo)
// Output: instancia de Lexer
Lexer::Lexer(const std::string& file) : filename(file) {}

// Lee el archivo línea por línea y las almacena en vector
// Input: ninguno (usa filename interno)
// Output: true si lectura exitosa, false si falla
bool Lexer::readFile() {
    std::ifstream file(filename);
    if (!file.is_open()) {
        Logger::error("No se pudo abrir el archivo: " + filename);
        return false;
    }

    Logger::info("Leyendo archivo: " + filename);

    std::string line;
    while (std::getline(file, line)) {
        lines.push_back(line);
    }

    file.close();
    Logger::info("Archivo leído: " + std::to_string(lines.size()) + " líneas");

    return true;
}
