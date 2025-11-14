#ifndef LEXER_H
#define LEXER_H

#include <string>
#include <vector>
#include <fstream>

// Lee archivo línea por línea
class Lexer {
private:
    std::string filename;
    std::vector<std::string> lines;

public:
    Lexer(const std::string& file);
    bool readFile();
    const std::vector<std::string>& getLines() const { return lines; }
    size_t getLineCount() const { return lines.size(); }
};

#endif // LEXER_H
