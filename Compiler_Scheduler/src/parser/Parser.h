#ifndef PARSER_H
#define PARSER_H

#include "Instruction.h"
#include "Lexer.h"
#include <vector>
#include <map>

// Parsea instrucciones RISC-V y resuelve labels
class Parser {
private:
    Lexer& lexer;
    std::vector<Instruction> instructions;
    std::map<std::string, int> labels;

public:
    Parser(Lexer& lex);
    bool parse();
    void resolveLabels();

    const std::vector<Instruction>& getInstructions() const { return instructions; }
    const std::map<std::string, int>& getLabels() const { return labels; }

    void printInstructions() const;
    void printLabels() const;
    bool saveToFile(const std::string& filename) const;
};

#endif // PARSER_H
