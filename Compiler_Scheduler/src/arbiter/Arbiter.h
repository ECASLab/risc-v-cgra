#ifndef ARBITER_H
#define ARBITER_H

#include <vector>
#include <map>
#include <string>

// Modela el arbitro del bus compartido entre PEs
class Arbiter {
public:
    enum class Policy {
        ROUND_ROBIN,
        PRIORITY,
        FAIR_SHARE
    };

    Arbiter(int num_pes, Policy policy = Policy::ROUND_ROBIN);
    ~Arbiter() = default;

    void reset();
    void requestBusAccess(int pe_id, int cycle);
    int getBusGrant(int cycle);
    bool canAccessBus(int pe_id, int cycle);
    void advanceCycle();

    std::map<int, int> getBusUsageStats() const;
    int getNextAvailableCycle(int pe_id, int from_cycle);

    // Estadisticas
    int getTotalContentions() const { return total_contentions_; }
    int getTotalBusAccesses() const { return total_bus_accesses_; }
    std::map<int, int> getContentionsByPE() const { return pe_contentions_; }
    std::map<int, int> getWaitCyclesByPE() const { return pe_wait_cycles_; }
    double getBusUtilization() const;

    void setPolicy(Policy policy) { policy_ = policy; }
    void setGrantLatency(int latency) { grant_latency_ = latency; }

    int getCurrentGrant() const { return current_grant_; }
    int getCurrentCycle() const { return current_cycle_; }
    Policy getPolicy() const { return policy_; }

private:
    int num_pes_;
    Policy policy_;
    int current_grant_;
    int current_cycle_;
    int grant_latency_;

    std::map<int, int> grant_history_;
    std::map<int, std::vector<int>> pending_requests_;
    std::map<int, int> pe_bus_usage_;

    int total_contentions_;
    int total_bus_accesses_;
    std::map<int, int> pe_contentions_;
    std::map<int, int> pe_wait_cycles_;

    int roundRobinSelect(int cycle);
    int prioritySelect(int cycle);
};

#endif // ARBITER_H
