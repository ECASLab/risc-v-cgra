#include "Logger.h"
#include <iomanip>
#include <chrono>
#include <ctime>

LogLevel Logger::currentLevel = LogLevel::INFO;
std::ofstream Logger::logFile;
bool Logger::fileLogging = false;

// Inicializa el logger, opcionalmente con archivo de salida
// Input: filename (ruta opcional para log file)
// Output: logger configurado
void Logger::init(const std::string& filename) {
    if (!filename.empty()) {
        logFile.open(filename, std::ios::app);
        if (logFile.is_open()) {
            fileLogging = true;
            info("Logger initialized with file: " + filename);
        }
    }
}

// Establece el nivel mínimo de logging
void Logger::setLevel(LogLevel level) {
    currentLevel = level;
}

// Convierte nivel de log a string
std::string Logger::levelToString(LogLevel level) {
    switch (level) {
        case LogLevel::DEBUG:   return "DEBUG";
        case LogLevel::INFO:    return "INFO";
        case LogLevel::WARNING: return "WARNING";
        case LogLevel::ERROR:   return "ERROR";
        default:                return "UNKNOWN";
    }
}

// Retorna código de color ANSI según nivel de log
std::string Logger::getColor(LogLevel level) {
    switch (level) {
        case LogLevel::DEBUG:   return "\033[0;36m"; // Cyan
        case LogLevel::INFO:    return "\033[0;32m"; // Green
        case LogLevel::WARNING: return "\033[0;33m"; // Yellow
        case LogLevel::ERROR:   return "\033[0;31m"; // Red
        default:                return "";
    }
}

std::string Logger::resetColor() {
    return "\033[0m";
}

// Registra mensaje con timestamp y nivel, a consola y archivo
// Input: level (nivel de log), message (mensaje)
// Output: mensaje loggeado con color y timestamp
void Logger::log(LogLevel level, const std::string& message) {
    if (level < currentLevel) return;

    auto now = std::chrono::system_clock::now();
    auto time = std::chrono::system_clock::to_time_t(now);
    std::stringstream ss;
    ss << std::put_time(std::localtime(&time), "%H:%M:%S");

    std::string logMessage = "[" + ss.str() + "][" + levelToString(level) + "] " + message;

    std::cout << getColor(level) << logMessage << resetColor() << std::endl;

    if (fileLogging && logFile.is_open()) {
        logFile << logMessage << std::endl;
        logFile.flush();
    }
}

void Logger::debug(const std::string& message) { log(LogLevel::DEBUG, message); }
void Logger::info(const std::string& message) { log(LogLevel::INFO, message); }
void Logger::warning(const std::string& message) { log(LogLevel::WARNING, message); }
void Logger::error(const std::string& message) { log(LogLevel::ERROR, message); }

void Logger::close() {
    if (logFile.is_open()) {
        logFile.close();
    }
}
