#ifndef REGISTER_INITIALIZER_H
#define REGISTER_INITIALIZER_H

#include <string>
#include <set>
#include <vector>
#include "../parser/Parser.h"

// Genera bloque de inicialización de registros para evitar valores indefinidos
class RegisterInitializer {
public:
    RegisterInitializer(const Parser& parser);
    ~RegisterInitializer() = default;

    // Analiza instrucciones y recopila registros usados
    void collectUsedRegisters();

    // Genera bloque de inicialización (addi rx, zero, 0)
    std::vector<std::string> generateInitBlock() const;

    // Obtiene conjunto de registros usados
    const std::set<std::string>& getUsedRegisters() const { return used_registers_; }

    // Guarda información de inicialización a archivo
    bool saveToFile(const std::string& filename) const;

private:
    const Parser& parser_;
    std::set<std::string> used_registers_;

    // Verifica si un registro debe inicializarse (no zero, no sp)
    bool shouldInitialize(const std::string& reg) const;
};

#endif // REGISTER_INITIALIZER_H
