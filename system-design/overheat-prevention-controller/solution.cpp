#include <algorithm>
#include <map>
#include <optional>
#include <string>
#include <utility>
#include <vector>

// make Tick() the only operation that advances the simulation. setCoreLoad() merely records an input for that next transaction.
class OverheatPreventionController {
public:
    OverheatPreventionController(double passiveCoolingCapacity, double activeCoolingCapacityPerCore, const std::vector<std::string>& coreIds)
        : passiveCapacity_(passiveCoolingCapacity), activeCapacityPerCore_(activeCoolingCapacityPerCore) {
        for (const std::string& id : coreIds) {
            cores_.insert({id, Core{}});
        }
    }

    void setCoreLoad(double timestamp, const std::string& coreId, double loadWatts) {
        // Current load and requested load are different pieces of state. 
        // Replacing this optional also gives us "the latest request wins" for free.
        cores_.at(coreId).pendingLoad = loadWatts;

        // The API supplies a timestamp, but the specification says that a load
        // starts at the next tick. Therefore this timestamp does not enter the
        // thermal math; only consecutive tick timestamps do.
        (void)timestamp;
    }

    std::vector<std::string> tick(double timestamp) {
        // Save the externally visible state before doing any work. Comparing
        // only after all five stages prevents reporting temporary transitions.
        std::map<std::string, Status> statusBeforeTick;
        for (const auto& [id, core] : cores_) {
            statusBeforeTick.emplace(id, core.status);
        }

        // Stage 1: evolve with the OLD load and OLD cooling decision.
        // The first tick initializes the first interval, so no time has elapsed.
        if (hasTicked_) {
            updateTemperatures(timestamp - lastTickTimestamp_);
        }

        // Stages 2-4 must stay in this order. This ordering is the architecture
        // of the solution, not a small implementation detail.
        shutDownOverheatedCores();       // Stage 2
        applyPendingLoadsAndRestarts();  // Stage 3
        selectActiveCooling();           // Stage 4 (for the NEXT interval)

        // Stage 5: report only final visible changes. std::map iteration also
        // gives the required alphabetical ordering by core ID.
        std::vector<std::string> changes;
        for (const auto& [id, core] : cores_) {
            if (core.status != statusBeforeTick.at(id)) {
                changes.push_back(id + "=" + statusName(core.status));
            }
        }

        lastTickTimestamp_ = timestamp;
        hasTicked_ = true;
        return changes;
    }

private:
    enum class Status {
        Idle,
        Cooling,
        Shutdown,
    };

    struct Core {
        double temperature = kAmbientTemperature;
        double load = 0.0;                  // Heat produced in this interval.
        std::optional<double> pendingLoad;  // Request for the next tick.
        Status status = Status::Idle;
    };

    static constexpr double kAmbientTemperature = 20.0;
    static constexpr double kShutdownTemperature = 80.0;
    static constexpr double kRestartTemperature = 50.0;
    static constexpr double kForceCoolingTemperature = 60.0;
    static constexpr double kMaxUncooledRisePerSecond = 0.5;
    static constexpr double kTemperaturePerWattSecond = 0.02;
    static constexpr double kBuiltInPassiveDemand = 2.0;

    // A map is sufficient and makes output sorting automatic. An unordered_map
    // plus a final sort is equally valid.
    std::map<std::string, Core> cores_;
    double passiveCapacity_;
    double activeCapacityPerCore_;

    // LEARNING NOTE: time belongs to the controller, not to each core. All
    // cores advance together from one global tick boundary to the next.
    bool hasTicked_ = false;
    double lastTickTimestamp_ = 0.0;

    static const char* statusName(Status status) {
        switch (status) {
            case Status::Idle:
                return "idle";
            case Status::Cooling:
                return "cooling";
            case Status::Shutdown:
                return "shutdown";
        }
        return "";  // All enum values are handled above.
    }

    static double demandFor(const Core& core) {
        // Shutdown cores have load == 0, but still contribute 2 W of demand.
        return core.load + kBuiltInPassiveDemand;
    }

    double totalPassiveDemand() const {
        double total = 0.0;
        for (const auto& [id, core] : cores_) {
            (void)id;
            total += demandFor(core);
        }
        return total;
    }

    // The problem's sequence is 1, 2, 3, 5, ... (not 0, 1, 1, 2, ...).
    // The penalty is the cumulative SUM of 10 / fibonacciValue.
    static double vibrationPenaltyPercent(int activeCount) {
        double penalty = 0.0;
        double current = 1.0;
        double next = 2.0;

        for (int i = 0; i < activeCount; ++i) {
            penalty += 10.0 / current;  // 10.0 avoids integer division.
            const double following = current + next;
            current = next;
            next = following;
        }
        return penalty;
    }

    double effectivePassiveCapacity(int activeCount) const {
        return passiveCapacity_ * (1.0 - vibrationPenaltyPercent(activeCount) / 100.0);
    }

    static double passiveCoolingFor(const Core& core, double totalDemand, double effectiveCapacity) {
        const double demand = demandFor(core);

        if (totalDemand <= effectiveCapacity) {
            return demand;
        }

        return effectiveCapacity * demand / totalDemand;
    }

    int activeCoreCount() const {
        int count = 0;
        for (const auto& [id, core] : cores_) {
            (void)id;
            if (core.status == Status::Cooling) {
                ++count;
            }
        }
        return count;
    }

    void updateTemperatures(double elapsedSeconds) {
        const int activeCount = activeCoreCount();
        const double effectiveCapacity = effectivePassiveCapacity(activeCount);
        const double totalDemand = totalPassiveDemand();

        for (auto& [id, core] : cores_) {
            (void)id;
            const double passiveCooling = passiveCoolingFor(core, totalDemand, effectiveCapacity);
            const double activeCooling = core.status == Status::Cooling ? activeCapacityPerCore_ : 0.0;
            const double netHeat = core.load - passiveCooling - activeCooling;

            core.temperature += kTemperaturePerWattSecond * netHeat * elapsedSeconds;
            core.temperature = std::max(kAmbientTemperature, core.temperature);
        }
    }

    void shutDownOverheatedCores() {
        for (auto& [id, core] : cores_) {
            (void)id;
            if (core.temperature >= kShutdownTemperature) {
                core.status = Status::Shutdown;
                core.load = 0.0;
            }
        }
    }

    void applyPendingLoadsAndRestarts() {
        for (auto& [id, core] : cores_) {
            (void)id;
            if (!core.pendingLoad.has_value()) {
                continue;
            }

            const double requestedLoad = *core.pendingLoad; //treated as a pointer cuz std::optional<double>

            if (core.status != Status::Shutdown) {
                core.load = requestedLoad;
            } else if (core.temperature < kRestartTemperature) {
                core.load = requestedLoad;
                core.status = Status::Idle;
            }

            core.pendingLoad.reset();
        }
    }

    void selectActiveCooling() {
        // Recompute from scratch for the next interval. Shutdown cores stay
        // shutdown; every running core begins as an uncooled candidate.
        for (auto& [id, core] : cores_) {
            (void)id;
            if (core.status != Status::Shutdown) {
                core.status = Status::Idle;
            }
        }

        int activeCount = 0;
        const double totalDemand = totalPassiveDemand();

        // LEARNING NOTE (the hardest missing part in your attempt): this is a
        // least-fixed-point loop. Adding fans worsens passive cooling, which may
        // force more fans. Every non-final pass activates at least one new core,
        // so the loop terminates after at most number-of-cores passes.
        while (true) {
            const double effectiveCapacity = effectivePassiveCapacity(activeCount);
            std::vector<Core*> newlyRequired;

            for (auto& [id, core] : cores_) {
                (void)id;
                if (core.status != Status::Idle) {
                    continue;
                }

                const double passiveCooling = passiveCoolingFor(core, totalDemand, effectiveCapacity);
                const double riseWithoutActiveCooling = kTemperaturePerWattSecond * (core.load - passiveCooling);

                // Both comparisons are strict because the statement says
                // "above 60" and "faster than 0.5 C/s."
                if (core.temperature > kForceCoolingTemperature || riseWithoutActiveCooling > kMaxUncooledRisePerSecond) {
                    newlyRequired.push_back(&core);
                }
            }

            if (newlyRequired.empty()) {
                break;
            }

            for (Core* core : newlyRequired) {
                core->status = Status::Cooling;
            }
            activeCount += static_cast<int>(newlyRequired.size());
        }
    }
};
