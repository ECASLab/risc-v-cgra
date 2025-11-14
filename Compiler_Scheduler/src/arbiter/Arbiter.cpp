#include "Arbiter.h"
#include "../utils/Logger.h"
#include <algorithm>

// Constructor
// Input: numero de PEs, politica de arbitraje (round_robin o priority)
Arbiter::Arbiter(int num_pes, Policy policy)
    : num_pes_(num_pes), policy_(policy), current_grant_(0), 
      current_cycle_(0), grant_latency_(1),
      total_contentions_(0), total_bus_accesses_(0) {
    
    // Inicializar estadísticas de uso
    for (int i = 0; i < num_pes_; i++) {
        pe_bus_usage_[i] = 0;
        pe_contentions_[i] = 0;
        pe_wait_cycles_[i] = 0;
    }

    Logger::info("Arbiter inicializado: " + std::to_string(num_pes_) + 
                 " PEs, política Round-Robin (acceso paralelo habilitado)");
}

// Reinicia el estado del arbitro y todas las estadisticas
void Arbiter::reset() {
    current_grant_ = 0;
    current_cycle_ = 0;
    grant_history_.clear();
    pending_requests_.clear();
    total_contentions_ = 0;
    total_bus_accesses_ = 0;
    
    // Reiniciar estadísticas
    for (auto& pair : pe_bus_usage_) {
        pair.second = 0;
    }
    for (auto& pair : pe_contentions_) {
        pair.second = 0;
    }
    for (auto& pair : pe_wait_cycles_) {
        pair.second = 0;
    }
}

// Registra una solicitud de acceso al bus por parte de un PE
// Input: ID del PE solicitante, ciclo en el que se hace la solicitud
void Arbiter::requestBusAccess(int pe_id, int cycle) {
    if (pe_id < 0 || pe_id >= num_pes_) {
        Logger::warning("Arbiter: PE_id inválido: " + std::to_string(pe_id));
        return;
    }

    // Registrar solicitud
    pending_requests_[cycle].push_back(pe_id);
    
    // Incrementar estadísticas de uso
    pe_bus_usage_[pe_id]++;
    total_bus_accesses_++;
    
    // Con acceso paralelo, NO hay contención entre diferentes PEs
    // Solo registramos si el MISMO PE intenta múltiples accesos en el mismo ciclo
    int same_pe_count = 0;
    for (int pe : pending_requests_[cycle]) {
        if (pe == pe_id) same_pe_count++;
    }
    
    if (same_pe_count > 1) {
        total_contentions_++;
        pe_contentions_[pe_id]++;
    }
}

// Determina que PE obtiene acceso al bus en un ciclo dado
// Input: numero de ciclo
// Output: ID del PE que obtiene el grant
int Arbiter::getBusGrant(int cycle) {
    // Con acceso paralelo, TODOS los PEs pueden acceder al bus simultáneamente
    // Esta función ahora simplemente verifica que el PE tenga una solicitud válida
    
    // Si ya fue calculado, retornar del historial
    if (grant_history_.find(cycle) != grant_history_.end()) {
        return grant_history_[cycle];
    }

    // En el modelo de acceso paralelo, siempre hay grant disponible
    // El scheduling se encarga de asignar PEs diferentes
    int granted_pe = cycle % num_pes_;  // Default round-robin para tracking
    
    // Guardar en historial
    grant_history_[cycle] = granted_pe;
    
    return granted_pe;
}

// Verifica si un PE puede acceder al bus en un ciclo dado
// Input: ID del PE, numero de ciclo
// Output: true si puede acceder, false si no
bool Arbiter::canAccessBus(int pe_id, int /* cycle */) {
    // Con acceso paralelo, todos los PEs pueden acceder simultáneamente
    // Simplemente verificamos que el PE esté en rango válido
    return pe_id >= 0 && pe_id < num_pes_;
}

// Avanza el arbitro al siguiente ciclo
void Arbiter::advanceCycle() {
    current_cycle_++;
    current_grant_ = (current_grant_ + 1) % num_pes_;
}

// Obtiene las estadisticas de uso del bus por cada PE
// Output: mapa con PE_id -> numero de accesos
std::map<int, int> Arbiter::getBusUsageStats() const {
    return pe_bus_usage_;
}

// Calcula el siguiente ciclo disponible para que un PE acceda al bus
// Input: ID del PE, ciclo desde el cual buscar
// Output: numero de ciclo disponible
int Arbiter::getNextAvailableCycle(int /* pe_id */, int from_cycle) {
    // Con acceso paralelo, el siguiente ciclo disponible es inmediato
    return from_cycle;
}

// Selecciona el PE que recibe grant usando politica Round-Robin
// Input: numero de ciclo actual
// Output: ID del PE seleccionado
int Arbiter::roundRobinSelect(int cycle) {
    // Round-robin simple: el grant va rotando PE0 -> PE1 -> PE2 -> PE3 -> PE0...
    
    int grant = cycle % num_pes_;
    
    // Si hay solicitudes pendientes para este ciclo, verificar si el PE con grant
    // realmente lo solicitó
    if (pending_requests_.find(cycle) != pending_requests_.end()) {
        const auto& requests = pending_requests_[cycle];
        
        // Si el PE con grant no lo solicitó, buscar el siguiente que sí lo hizo
        if (std::find(requests.begin(), requests.end(), grant) == requests.end()) {
            // Buscar el siguiente PE en orden round-robin que tenga solicitud
            for (int offset = 1; offset < num_pes_; offset++) {
                int candidate = (grant + offset) % num_pes_;
                if (std::find(requests.begin(), requests.end(), candidate) != requests.end()) {
                    return candidate;
                }
            }
            // Si nadie solicitó, retornar el grant original (ciclo vacío)
        }
    }
    
    return grant;
}

// Selecciona el PE que recibe grant usando politica de prioridades
// Input: numero de ciclo actual
// Output: ID del PE seleccionado (menor ID = mayor prioridad)
int Arbiter::prioritySelect(int cycle) {
    // Implementación con prioridades: PE0 tiene mayor prioridad
    if (pending_requests_.find(cycle) == pending_requests_.end()) {
        return cycle % num_pes_;  // Default: round-robin
    }

    const auto& requests = pending_requests_[cycle];
    if (requests.empty()) {
        return cycle % num_pes_;
    }

    // Retornar el PE con menor ID (mayor prioridad)
    return *std::min_element(requests.begin(), requests.end());
}

// Calcula el porcentaje de utilizacion del bus
// Output: porcentaje de utilizacion (0.0 - 100.0)
double Arbiter::getBusUtilization() const {
    if (current_cycle_ == 0) return 0.0;
    
    // Calcular utilización del bus: ciclos usados / ciclos totales
    double utilization = (static_cast<double>(total_bus_accesses_) / current_cycle_) * 100.0;
    return utilization;
}
