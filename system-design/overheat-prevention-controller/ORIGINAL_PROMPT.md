You are implementing the firmware controller that prevents a multi-core microprocessor from overheating. Every core runs a workload that produces heat proportional to its configured load, and all cores share a fixed cooling capacity. The operating system (OS) is in charge of assigning workloads via SetCoreLoad, and drives the controller forward via Tick on a cadence of its choosing to learn how each core's status has changed.

# Scoring

The list below shows the test-case categories used to evaluate your submission, roughly ordered from most to least impactful. Use this as guidance for where to invest effort; categories are intentionally broad and can overlap, so don't over-optimize for labels.

* State Management
* Core Logic
* Edge Cases
* Scalability/Performance

# Overview

Implement the OverheatPreventionController class with the following operations:

* __init__ — (constructor) initializes the controller with its cooling capacities and cores.
* SetCoreLoad — lazily updates a core's configured workload; can also restart a shut down core.
* Tick — advances the controller's internal state to the given timestamp, processes any pending load changes and returns the cores whose status has changed since the previous Tick.

The controller doesn't have temperature sensors; instead, it must calculate the temperature of each core based on the configured loads and the cooling layout, as defined in Thermal Dynamics. Loads are given in watts (W).

# Functions

    __init__(passive_cooling_capacity: float,
             active_cooling_capacity_per_core: float, core_ids: list[string])

* This represents the constructor of the class in whatever programming language being used.
* Initializes the controller with the given passive_cooling_capacity (the shared passive cooling budget, in watts), active_cooling_capacity_per_core (the dedicated per-core active-cooling capacity, in watts, applied uniformly to every core when engaged), and the list of valid core_ids.
* All cores start at ambient temperature (20.0°C), running, with load 0 and active cooling off (i.e. status idle, see Tick below).
* You may assume:
  * 1 ≤ R < 2^10, where R is the total number of cores.
  * passive_cooling_capacity > 0 and active_cooling_capacity_per_core > 0.
  * All core identifiers are unique.

    SetCoreLoad(timestamp: float, core_id: string, load_watts: float)

* Records a new configured load for the given core. Performs no thermal arithmetic. The new load only takes effect at the next Tick.
* If two or more SetCoreLoad calls land on the same core between two Ticks, only the last one takes effect.
* If the core is currently shut down, this call also acts as a manual restart attempt: it will restart the core with the new load, but only if the core's temperature observed at the next Tick is strictly below 50°C. Otherwise the restart is discarded and the core stays shut down with load 0 — restarting later requires another SetCoreLoad call.
* If the core is currently running, the new load is simply recorded and processed normally at the next Tick.
* You may assume core_id always exists and load_watts is always within [0, 2^15).

    Tick(timestamp: float) -> list[string]

* It does, in order:
  1. Advances the controller to timestamp in a single step. See Thermal Dynamics for how temperatures evolve.
  2. Shuts down any core whose temperature has reached 80°C (its load is cleared to 0).
  3. Processes any pending load changes, including restart attempts on shut down cores.
  4. Decides which cores should have active cooling engaged for the upcoming interval. See Active Cooling for details.
* Returns the cores whose status has changed since the previous Tick (or diverged from the initial state), where a core's status is one of:
  * idle — running, active cooling off.
  * cooling — running, active cooling engaged for the upcoming interval.
  * shutdown — shut down.
* Each entry of the returned list has the format "core_id=status". The list is sorted alphabetically by core_id. An empty list means nothing has changed.

# Thermal Dynamics

At every Tick, the controller first computes each core's temperature at the given timestamp. A core's temperature is determined as follows:

* Every core's temperature evolves linearly at a rate of 0.02°C/s per watt of net heat balance, positive or negative. Net heat balance is the core's load minus all its allocated cooling. When cooling down, a core's temperature will never drop below 20.0°C.
* The cooler distributes its effective passive cooling capacity across the cores according to their passive cooling demand. The demand is load + 2 W per core, where +2 W represents the maximum passive heat dissipation per core. The passive cooling distribution is as follows:
  * If the total passive demand fits within the effective passive capacity, every core's demand is fully met.
  * Otherwise, capacity is distributed proportionally to each core's demand.
* The cooler’s effective passive cooling capacity depends on whether active cooling was engaged by the previous Tick. The effect is described below.

# Active Cooling

At the end of each Tick, the controller decides which cores should have active cooling engaged until the next Tick, when the decision will be reassessed from scratch. Active cooling works as follows:

* Each core has a dedicated active-cooling channel that delivers exactly active_cooling_capacity_per_core watts on top of the passive cooling when engaged on that core.
* Active cooling is expensive, therefore it should be engaged on as few cores as possible to satisfy these rules:
  * Any core whose temperature is rising faster than 0.5°C/s must be engaged.
  * Any core whose temperature is above 60°C must be engaged.
* When active cooling is on, the passive cooler vibrates and runs less efficiently. The efficiency decreases proportionally to the number of cores that have active cooling engaged. When k cores are actively cooling, the total passive cooling capacity is reduced by vibration_penalty(k) percent, where:
  * vibration_penalty(0) = 0.
  * vibration_penalty(k) = Σ_{i=1..k} (10 / Fib_i), where Fib_i is the i-th term of the sequence 1, 2, 3, 5, 8, 13, ... (Fibonacci, starting from its second term).
* Because engaging active cooling on a core increases the vibration penalty for everyone, it can in turn lift other cores’ rates above 0.5°C/s and trigger their engagement as well within the same interval.

# Constraints

* All timestamps are globally ever-increasing. Operations will never arrive out of order.
* Timestamps are seconds since the Unix Epoch (Jan 1, 1970 UTC), as floating-point values with millisecond precision. They are positive and fit into 32 bits.
* Loads and cooling capacities are in watts, as floating-point values with milliwatt precision (3 decimal places).
* State transition thresholds and the active-cooling rate threshold are exact. Test inputs are constructed so that observed temperatures and rates stay clear of these thresholds by a margin that exceeds floating-point precision.
* 1 < N < 2^10, where N is the total number of operations given to the program.

# Input Format For Custom Testing

Input to the program is specified using a simple text format. The format and details of parsing are not relevant to answering the question but custom input can be used to help with development and debugging.

The first line must always be in the format below:

    Init <passive_cooling_capacity> <active_cooling_capacity_per_core> <core1> <core2> ...

Each subsequent input line may contain one of the instructions as in the format below:

    SetCoreLoad <timestamp> <core_id> <load_watts>
    Tick <timestamp>

An example input and its expected output is described below.

# Sample Case

Sample input for custom testing:

    Init 545 60 coreA coreB coreC
    SetCoreLoad 100.000 coreA 350.0
    SetCoreLoad 100.000 coreB 200.0
    SetCoreLoad 100.000 coreC 50.0
    Tick 100.000
    Tick 250.000
    SetCoreLoad 1099.000 coreA 350.0
    Tick 1100.000

Expected output:

    Tick=['coreA=cooling', 'coreB=cooling']
    Tick=['coreA=shutdown', 'coreB=idle']
    Tick=['coreA=cooling', 'coreB=cooling']

Explanation:

The controller manages a three-core processor with 545 W of shared passive cooling and 60 W of active cooling per core. All cores start at 20.0°C, running, with load 0 (status idle).

| Timestamp | Event | Temp A | Status A | Temp B | Status B |
|---|---|---:|---|---:|---|
| — | Init | 20.000 | idle | 20.000 | idle |
| 100.000 | SetCoreLoad ×3 (loads pending) | 20.000 | idle | 20.000 | idle |
| 100.000 | Tick | 20.000 | cooling | 20.000 | cooling |
| 250.000 | Tick | 82.75 | shutdown | 20.000† | idle |
| 1099.000 | SetCoreLoad coreA 350 (pending restart) | 82.75 | shutdown | 20.000† | idle |
| 1100.000 | Tick | 48.75 | cooling | 20.000† | cooling |

† clamped at the ambient floor of 20.0°C.

Per-Tick walkthrough:

* Tick 100.000 — first Tick: every core reads ambient regardless of the pending loads. The pending loads (350, 200, 50 W) are then committed and active cooling is decided for the upcoming interval. With no active cooling engaged the passive cooler is overloaded (352 + 202 + 52 = 606 W > 545 W), and coreA's would-be rate is (350 - 545 × 352 / 606) / 50 = 0.67 °C/s, above the 0.5°C/s threshold — so coreA's active cooling engages. Vibration drops effective passive capacity to 545 × 0.9 = 490.5 W; under that capacity coreB's would-be rate becomes (200 - 490.5 × 202 / 606) / 50 = 0.73 °C/s, also above the threshold, so coreB's active cooling engages too. Vibration grows to 15%, and coreC's rate is now (50 - 463.25 × 52 / 606) / 50 = 0.21 °C/s, still well below the threshold — coreC stays passive. coreA and coreB flip from idle to cooling, coreC is unchanged.

* Tick 250.000 (150 s later) — under the engaged set {coreA, coreB} and 15% vibration, coreA heated at ≈+0.42 °C/s, coreB cooled at ≈−0.29 °C/s (its 60 W of active cooling exceeds its passive deficit), and coreC heated at ≈+0.21 °C/s. coreA crosses 80°C and shuts down; its load is cleared to 0 and total demand falls to 2 + 202 + 52 = 256 W. Effective passive capacity (no engagement) of 545 W covers everyone fully — no core's rate exceeds 0.5°C/s, so active cooling disengages on both coreA and coreB. coreA flips from cooling to shutdown, coreB from cooling back to idle, coreC is unchanged.

* SetCoreLoad coreA 350 at 1099.000 records a pending load on the shut down core; the actual restart attempt happens on the next Tick.

* Tick 1100.000 (850 s after the previous Tick) — with no active cooling and full passive cover, every core drifts at −0.04 °C/s. coreA cools from 82.75°C down to 48.75°C, dipping below the 50°C restart line; the pending load is accepted and coreA restarts with load 350 W. The other two cores hit the 20°C ambient floor along the way. Total demand is back to 606 W (over capacity), and the same cascade as at Tick 100.000 re-engages active cooling on coreA and coreB. coreA goes straight from shutdown to cooling in this single Tick, coreB flips from idle to cooling, coreC is unchanged.
