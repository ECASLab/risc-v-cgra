#ifndef LOGGER_H
#define LOGGER_H

#include <iostream>
#include <fstream>
#include <string>
#include <sstream>

enum class LogLevel {
    DEBUG, INFO, WARNING, ERROR
};

// Sistema de logging con colores y timestamps
class Logger {
private:
    static LogLevel currentLevel;
    static std::ofstream logFile;
    static bool fileLogging;

    static std::string levelToString(LogLevel level);
    static std::string getColor(LogLevel level);
    static std::string resetColor();

public:
    static void init(const std::string& filename = "");
    static void setLevel(LogLevel level);
    static void log(LogLevel level, const std::string& message);

    static void debug(const std::string& message);
    static void info(const std::string& message);
    static void warning(const std::string& message);
    static void error(const std::string& message);
    static void close();
};

#endif // LOGGER_H
