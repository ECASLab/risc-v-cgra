#ifndef DEPENDENCY_H
#define DEPENDENCY_H

#include <string>

enum class DependencyType {
    RAW,
    WAR,
    WAW,
    MEMORY
};

// Representa una dependencia entre dos instrucciones
class Dependency {
private:
    int sourceInstrIndex;
    int destInstrIndex;
    DependencyType type;
    std::string resource;
    int distance;

public:
    Dependency(int src, int dst, DependencyType t, const std::string& res);

    int getSource() const { return sourceInstrIndex; }
    int getDest() const { return destInstrIndex; }
    DependencyType getType() const { return type; }
    std::string getResource() const { return resource; }
    int getDistance() const { return distance; }

    void setDistance(int d) { distance = d; }

    std::string typeToString() const;
    std::string toString() const;
};

#endif // DEPENDENCY_H
