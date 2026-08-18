#include <algorithm>
#include <map>
#include <optional>
#include <string>
#include <utility>
#include <vector>

// make Tick() the only operation that advances the simulation. setCoreLoad() merely records an input for that next transaction.
class OverheatPreventionController {
private: 
    double passiveCoolingCapacity_;
    double activeCoolingCapacityPerCore_;

    enum class state_t {
        IDLE,
        Cooling,
        Shutdown,
    };

    struct Core{
        double temperature = 20.0;
        double load = 0.0;
        std::optional<double> pendingLoad;
        state_t state = state_t::IDLE;
    };

    std::map<std::string, Core> cores;

    double lastTickTime = -1.0;

    void updateTemperatures(double timeDif){
        const int activeCount = activeCoreCount();
        const double effectiveCapacity = effectivePassiveCapacity(activeCount);
        const double totalDemand = totalPassiveDemand();
        for (auto& [id, core] : cores) {
            (void)id;
            const double passiveCooling = passiveCoolingFor(core, totalDemand, effectiveCapacity);
            const double activeCooling = (core.state == state_t::Cooling) ? activeCoolingCapacityPerCore_ : 0.0;
            
            const double netHeat = core.load - passiveCooling - activeCooling;

            core.temperature += 0.02 * netHeat * timeDif;
            core.temperature = std::max(20.0, core.temperature);
        }
    }

    int activeCoreCount(){
        int count = 0;
        for (const auto& [id, core] : cores){
            if (core.state == state_t::Cooling){
                count++;
            }
        }
        return count;
    }

    double effectivePassiveCapacity(int activeCount) {
        double curr = 1;
        double next = 2;
        double penalty = 0.0;
        for (int i = 0; i < activeCount; i++){
            penalty += 10.0 / curr;
            double following = curr + next;
            curr = next;
            next = following;
        }
        return passiveCoolingCapacity_ * (1.0 - (penalty / 100.0));
    }

    double totalPassiveDemand() {
        double total = 0.0;
        for (const auto& [id, core] : cores) {
            (void)id;
            total += core.load + 2.0;
        }
        return total;
    }

    double passiveCoolingFor(Core& core, double totalDemand, double effectiveCapacity){
        double demand = core.load + 2.0;

        if (totalDemand <= effectiveCapacity) {
            return demand;
        }

        return effectiveCapacity * (demand / totalDemand);
    }

    void applyPendingLoadsAndRestarts(){
        for (auto& [id, core] : cores) {
            if (!core.pendingLoad.has_value()){
                continue;
            }
            if (core.state != state_t::Shutdown) {
                core.load = *core.pendingLoad;
            } else if (core.temperature < 50.0) {
                core.load = *core.pendingLoad;
                core.state = state_t::IDLE;
            }
            core.pendingLoad.reset();
        }
    }

    void selectActiveCooling(){
        for (auto& [id, core] : cores) {
            (void)id;
            if (core.state != state_t::Shutdown) {
                core.state = state_t::IDLE;
            }
        }
        int activeCount = 0;
        double totalDemand = totalPassiveDemand();
        while (true){
            int count = 0;
            double effectiveCapacity = effectivePassiveCapacity(activeCount);

            for (auto& [id, core] : cores){
                if (core.state != state_t::IDLE) continue;

                const double passiveCooling = passiveCoolingFor(core, totalDemand, effectiveCapacity);
                const double riseWithoutActiveCooling = 0.02 * (core.load - passiveCooling);
                if (riseWithoutActiveCooling > 0.5 || core.temperature > 60.0){
                    core.state = state_t::Cooling;
                    count++;
                }
            }
            if (!count) break;
            activeCount += count;
        }
    }

    const char* stateName(state_t state) {
        switch (state) {
            case state_t::IDLE:
                return "idle";
            case state_t::Cooling:
                return "cooling";
            case state_t::Shutdown:
                return "shutdown";
        }
        return "";
    }

    void shutdownOverheatedCores(){
        for (auto& [id, core] : cores){
            (void)id;
            if (core.temperature >= 80.0) {
                core.state = state_t::Shutdown;
                core.load = 0.0;
            }
        }
    }

public:
    OverheatPreventionController(double passiveCoolingCapacity, double activeCoolingCapacityPerCore, const std::vector<std::string>& coreIds)
    : passiveCoolingCapacity_(passiveCoolingCapacity), activeCoolingCapacityPerCore_(activeCoolingCapacityPerCore){
        for (auto& id : coreIds){
            cores.insert({id, Core{}});
        }
    }

    void setCoreLoad(double timestamp, const std::string& coreId, double loadWatts) {
        cores.at(coreId).pendingLoad = loadWatts;
        (void)timestamp;
    }

    std::vector<std::string> tick(double timestamp) {
        std::map<std::string, state_t> stateBeforeTick;
        for (const auto& [id, core] : cores) {
            stateBeforeTick.emplace(id, core.state);
        }

        if (lastTickTime != -1.0) {
            updateTemperatures(timestamp - lastTickTime);
        }

        shutdownOverheatedCores();       // Stage 2
        applyPendingLoadsAndRestarts();  // Stage 3
        selectActiveCooling();           // Stage 4 (for the NEXT interval)

        std::vector<std::string> changes;
        for (const auto& [id, core] : cores) {
            if (core.state != stateBeforeTick.at(id)) {
                changes.push_back(id + "=" + stateName(core.state));
            }
        }

        lastTickTime = timestamp;
        return changes;
    }

};