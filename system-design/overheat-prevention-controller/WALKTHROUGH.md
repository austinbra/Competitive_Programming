# Overheat Prevention Controller: How to Think Before You Code

This was a difficult one-shot problem. The density came from the interaction of
timing rules, state transitions, and formulas—not from an advanced data
structure. Your first instinct, a map from core ID to per-core state, was good.
The missing step was turning the prose into an executable model before typing.

This guide explains that modeling process in the order you should perform it in
an interview.

## 1. First classify the problem

This is not a traditional LeetCode problem where the full input arrives once and
one algorithm returns an answer. It exposes an object that receives calls over
time:

```text
setCoreLoad(...)
tick(...)
setCoreLoad(...)
tick(...)
...
```

That makes it a **stateful simulation** and an **object-oriented design (OOD)**
question. It exercises skills that also matter in larger system design:

- finding the source of truth;
- separating commands from state changes;
- defining transaction boundaries;
- making ordering rules explicit;
- preserving invariants;
- distinguishing stored state from derived state.

It is not yet distributed-system design. There are no services, databases,
networks, replicas, queues, or availability tradeoffs. Do not reach for those
concepts here. Solve the state machine first.

## 2. What to write while reading the prompt

Long prompts become manageable when you sort every sentence into one of five
buckets. Use this scratch template:

```text
ENTITIES:
OPERATIONS:
PERSISTENT STATE:
ORDERING / TRANSITIONS:
FORMULAS / INVARIANTS:
OUTPUT:
```

For this problem, the result is:

### Entities

```text
one controller
many cores identified by string IDs
```

### Operations

```text
setCoreLoad(timestamp, coreId, loadWatts)
tick(timestamp) -> list of status changes
```

### Persistent state

Per core:

```text
temperature
current load
pending load, if any
visible status
```

Controller-wide:

```text
passive capacity
active capacity per core
whether any tick has happened
last tick timestamp
```

### Exact tick order

```text
1. Evolve temperature using OLD decisions.
2. Shut down cores at or above 80 C.
3. Apply pending loads or attempt restarts.
4. Select active cooling for the NEXT interval.
5. Compare and return final status changes.
```

### Formulas and invariants

```text
demand = load + 2
net heat = load - passive cooling - active cooling
temperature delta = 0.02 * net heat * elapsed seconds
temperature >= 20
shutdown => load == 0 and no active cooling
```

### Output

```text
only visible statuses that changed during this tick
format: "core_id=status"
alphabetical by core ID
```

Once this page exists, rereading the original prompt should be rare. You return
to the prompt only to resolve an ambiguity or verify a threshold.

## 3. Read for time words before formulas

Words such as **current**, **pending**, **previous**, **next**, **before**,
**after**, and **until** are architectural clues. Circle them.

The sentence "the load is processed at the next tick" proves that one `load`
field is insufficient. At any instant, a core may have:

```text
current load = 40 W       (heating it now)
pending load = 10 W       (takes effect at the next boundary)
```

Your attempt stored only `loadWatts`, so the program had no way to represent
that valid situation. This is not a minor coding bug; it means the state model
cannot express the problem.

The fix is:

```cpp
double load = 0.0;
std::optional<double> pendingLoad;
```

This pattern appears constantly in interviews:

- current configuration vs pending configuration;
- committed balance vs pending transaction;
- displayed document vs unsaved edit;
- active deployment vs requested deployment.

Whenever an action takes effect later, ask whether you need both **current** and
**pending** state.

## 4. Commands are not always state transitions

`setCoreLoad()` sounds as if it should set the load. According to the contract,
it actually records an intent:

```cpp
core.pendingLoad = loadWatts;
```

`tick()` is the transaction boundary that commits it.

This separation gives three useful properties:

1. Calls between ticks cannot retroactively change an interval already underway.
2. Multiple calls naturally collapse to the latest value.
3. Every core changes configuration at one well-defined boundary.

In larger systems, the equivalent ideas are queued commands, staged writes,
event-loop turns, frame boundaries, and database commits.

## 5. Store facts; derive summaries

You started maintaining `activelyCooling`. That is a value the program can
derive by scanning the cores:

```cpp
int activeCount = 0;
for (const auto& [id, core] : cores) {
    if (core.status == Status::Cooling) {
        ++activeCount;
    }
}
```

If both the statuses and a separate count are mutable, every transition must
update both perfectly. A missed shutdown or restart makes them disagree.

Prefer one source of truth unless performance measurements force a cache.

The same reasoning removes a separate `activeCooling` boolean. Visible status
already tells us:

```text
Cooling  => active cooling is on
Idle     => it is off
Shutdown => it is off
```

Useful interview question:

> Is this field an independent fact, or can it be derived from another field?

## 6. Put time at the level where it changes

Your per-core timestamp fields were understandable, but all cores advance on the
same `tick(timestamp)`. Therefore elapsed time is global:

```cpp
elapsed = timestamp - lastTickTimestamp;
```

The timestamp passed to `setCoreLoad()` does not control thermal evolution,
because the request takes effect only at a tick boundary.

A rule of thumb:

- if objects advance independently, each may need its own clock;
- if one operation advances every object together, the owner usually holds the
  clock.

## 7. Treat `tick()` as a transaction pipeline

Write this skeleton before any thermal helper:

```cpp
vector<string> tick(double timestamp) {
    saveStatuses();

    if (hasTicked) {
        updateTemperatures(timestamp - lastTickTimestamp);
    }

    shutDownOverheatedCores();
    applyPendingLoadsAndRestarts();
    selectActiveCooling();

    auto result = collectStatusChanges();
    lastTickTimestamp = timestamp;
    hasTicked = true;
    return result;
}
```

This is the backbone. Each helper can now be implemented and tested in
isolation. More importantly, you have resolved the temporal meaning of every
field before doing math.

### Why the order matters

Suppose a core uses 100 W during `[0, 30]`, and at time 10 someone requests
0 W. At `tick(30)`:

1. It first heats for 30 seconds using 100 W.
2. It may shut down at 80 C.
3. Only then is the pending 0 W processed.

Applying the pending value first would rewrite history.

Likewise, cooling chosen at `tick(30)` cannot affect the heat calculation for
`[0, 30]`; it applies to the next interval.

## 8. Translate prose thresholds into a transition table

Do not scatter state transitions throughout the code. Write a table:

| Current condition | Event at tick | Final effect |
|---|---|---|
| running and temperature `< 80` | no pending load | remain running |
| running and temperature `>= 80` | thermal update ends | shutdown, load becomes 0 |
| running | pending load exists | replace current load |
| shutdown and temperature `< 50` | pending load exists | restart with requested load |
| shutdown and temperature `>= 50` | pending load exists | discard request, remain shutdown |
| shutdown | no request | remain shutdown even after becoming cool |

Notice the strictness:

```text
80.0 C shuts down       (>= 80)
50.0 C cannot restart   (< 50 is required)
above 60 must cool      (> 60)
exactly 0.5 C/s is okay (> 0.5 requires cooling)
```

Boundary words are favorite hidden-test targets.

## 9. Separate the three thermal concepts

The prompt describes **demand**, **allocation**, and **effect**. They are not the
same thing.

### Passive demand

```cpp
demand = load + 2.0;
```

This says how much passive cooling a core could use. It is not necessarily how
much it receives. Shutdown cores still demand 2 W.

### Passive allocation

If capacity covers total demand, each core receives its full demand. Otherwise:

```cpp
share = effectiveCapacity * coreDemand / totalDemand;
```

Compute total demand and effective capacity once per selection round, then use
the same values for all cores. Recomputing a changing total inside the loop
would accidentally make allocation depend on iteration order.

### Thermal effect

```cpp
netHeat = load - passiveShare - activeShare;
temperature += 0.02 * netHeat * elapsed;
temperature = max(20.0, temperature);
```

Units are an excellent self-check:

```text
watts of net heat
* 0.02 degrees / (watt * second)
* seconds
= degrees
```

If elapsed time or `0.02` is absent, the units expose the error.

## 10. Understand the cascade as a fixed point

This is the genuinely tricky part.

Let `S` be the set of actively cooled cores. The passive capacity depends on
`|S|`. Lower passive capacity may make more cores violate the uncooled-rate
rule, expanding `S` again:

```text
assume no active cores
        |
        v
compute passive capacity for |S|
        |
        v
add every running core that now requires cooling
        |
        +---- if anything was added, repeat
        |
        v
no additions: stable answer
```

This stable answer is a **fixed point**: running the rule again no longer changes
the set.

Starting from the empty set finds the least fixed point, which is why it uses as
few cores as possible. The reasoning is:

1. A core added in some round violates a mandatory rule at that round's active
   count.
2. Adding active cores only increases vibration penalty and reduces passive
   capacity.
3. Therefore an already-required core cannot become unnecessary in a later
   round.
4. Each non-final round adds at least one core, so there are at most `N` rounds.

This pattern generalizes to dependency propagation, build invalidation, access
policy closure, spreadsheet recalculation, and resource-pressure cascades.

## 11. A numerical cascade example

Assume:

```text
passive capacity = 77 W
coreA load = 100 W, demand = 102 W
coreB load = 50 W,  demand = 52 W
total demand = 154 W
```

With no active cooling, passive shares are:

```text
A: 77 * 102 / 154 = 51 W
B: 77 *  52 / 154 = 26 W
```

Uncooled rise rates:

```text
A: 0.02 * (100 - 51) = 0.98 C/s  -> must cool
B: 0.02 * ( 50 - 26) = 0.48 C/s  -> okay for now
```

One active core creates a 10% vibration penalty, so effective passive capacity
becomes `69.3 W`. Core B now receives:

```text
69.3 * 52 / 154 = 23.4 W
```

Its new uncooled rise rate is:

```text
0.02 * (50 - 23.4) = 0.532 C/s
```

Now B must also cool. A one-pass algorithm misses B.

## 12. C++ lessons from your attempt

### Scoped enums need qualification

```cpp
enum class Status { Idle, Cooling, Shutdown };

Status s = Status::Idle;
```

Writing just `idle` does not work with `enum class` / `enum struct`.

### Give state structs safe defaults

```cpp
struct Core {
    double temperature = 20.0;
    double load = 0.0;
    optional<double> pendingLoad;
    Status status = Status::Idle;
};
```

Then `Core{}` is a complete valid initial core. You avoid uninitialized members
and fragile positional constructor arguments.

### Mutating structured bindings need references

```cpp
for (auto& [id, core] : cores) {       // can mutate real core
    core.load = 0;
}

for (const auto& [id, core] : cores) { // read-only, no copy
}
```

This version copies and silently mutates only the copy:

```cpp
for (auto [id, core] : cores) {
}
```

### Prefer `.at()` when the key must exist

```cpp
Core& core = cores.at(coreId);
```

`cores[coreId]` inserts a default value if the ID is missing. `.at()` expresses
the contract that IDs are preconfigured.

### Watch numeric types in formulas

```cpp
10 / fibonacci     // integer division when both are integers
10.0 / fibonacci   // floating-point division
```

## 13. Complexity: choose the simple acceptable design

Each fixed-point round scans every core. A round that is not final activates at
least one new core, so the worst case is:

```text
time per tick: O(N^2)
memory:        O(N)
```

For roughly one thousand cores, this is generally fine in an interview. Say the
complexity out loud and connect it to the constraint. Do not optimize merely
because a loop is nested.

If the interviewer demands better performance, derive a threshold-based or
sorted approach only after the clear version is correct.

## 14. A practical 90-minute interview plan

### Minutes 0-10: extract, do not code

Write:

```text
entities
operations
state
five tick stages
formulas
strict thresholds
```

Ask clarifying questions if the original statement is unclear about timestamp
monotonicity, invalid core IDs, duplicate IDs, or negative loads.

### Minutes 10-20: design the smallest valid state

Make every field justify itself with this sentence:

> I must remember this because a future public call needs it and cannot derive it.

This would have exposed the need for `pendingLoad` and removed per-core time.

### Minutes 20-30: write the public-method skeleton

Implement `setCoreLoad()` and the ordered `tick()` outline with empty helpers.
At this point, explain the architecture to the interviewer. They can correct a
misread rule before you invest in details.

### Minutes 30-50: implement pure math helpers

Write and, if possible, quickly test:

```text
vibrationPenalty(activeCount)
effectivePassiveCapacity(activeCount)
totalPassiveDemand()
passiveCoolingFor(core, total, capacity)
```

Pure helpers are easier to verify than formulas embedded inside state changes.

### Minutes 50-65: implement thermal update and transitions

Keep evolution, shutdown, and pending-request processing in separate loops. This
makes the phase boundary obvious.

### Minutes 65-75: implement the fixed-point selection

State the termination proof while coding: every continuing iteration adds at
least one core, and no core is removed within the loop.

### Minutes 75-90: attack boundaries, not happy paths

Test:

- first tick performs no thermal evolution;
- multiple load requests before one tick;
- request during an interval does not rewrite that interval;
- temperature exactly 80 C;
- restart at exactly 50 C;
- failed restart is consumed;
- temperature floor at 20 C;
- shutdown cores still demand 2 W passive cooling;
- vibration creates a second cooling core;
- no status change returns an empty vector;
- output is alphabetically sorted.

## 15. What to say to the interviewer

A strong narration would sound like this:

> "This is a stateful simulation. Before coding, I want to separate persistent
> per-core state from controller-wide state and freeze the tick ordering. A core
> needs temperature, current load, pending load, and status. Time is global
> because tick advances all cores together. SetCoreLoad only records intent.
> Tick evolves the old interval, performs shutdowns, commits pending requests,
> computes the least fixed point for active cooling, and finally reports visible
> changes. The fixed-point loop is O(N squared) worst case because each
> continuing pass activates at least one core; that is acceptable for N around
> one thousand."

That explanation demonstrates design judgment even before the implementation is
complete.

## 16. How to practice this skill without AI dependence

For your next five long simulation problems, impose this rule:

> No C++ for the first ten minutes.

Produce only:

1. a state table;
2. an operation/phase list;
3. formulas with units;
4. boundary inequalities;
5. two hand-worked timelines.

Then code from that sheet. Afterward, compare failures to one of four causes:

```text
modeling error   - missing or redundant state
ordering error   - correct operations in the wrong phase
math error       - incorrect formula or unit
coding error     - syntax, reference/copy, container behavior
```

Your one-shot attempt was mostly a modeling-and-ordering miss, with a few C++
errors downstream. That is encouraging: you do not need a new advanced
algorithm. You need a repeatable way to compress prose before implementation.

## Files in this folder

- `solution.cpp` contains the interview-ready implementation with comments at
  the exact concepts that blocked your attempt.
- `solution_tests.cpp` contains focused assertions for delayed loads, shutdown,
  one-time restart, ordering, sorting, and the vibration cascade.

Compile and run the tests from this directory with:

```powershell
g++ -std=c++17 -Wall -Wextra -pedantic solution_tests.cpp -o solution_tests.exe
./solution_tests.exe
```
