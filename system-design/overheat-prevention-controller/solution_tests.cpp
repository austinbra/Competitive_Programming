#include <cassert>
#include <iostream>
#include <string>
#include <vector>

#include "solution_redo.cpp"

using Strings = std::vector<std::string>;

static void pendingLoadIsDelayedAndLatestRequestWins() {
    OverheatPreventionController controller(0.0, 0.0, {"coreA"});

    controller.setCoreLoad(1.0, "coreA", 100.0);
    controller.setCoreLoad(2.0, "coreA", 0.0);

    // The first tick applies only the latest request. It performs no thermal
    // evolution, and a 0 W core does not need cooling.
    assert(controller.tick(10.0) == Strings{});
    assert(controller.tick(1000.0) == Strings{});
}

static void oldLoadControlsTheIntervalThatJustEnded() {
    OverheatPreventionController controller(2.0, 0.0, {"coreA"});

    controller.setCoreLoad(0.0, "coreA", 102.0);
    assert(controller.tick(0.0) == Strings{"coreA=cooling"});

    // This does not erase the 102 W that is already heating the core during
    // [0, 30]. At t=30 the core reaches 80 C and shuts down before the pending
    // 0 W request is processed.
    controller.setCoreLoad(1.0, "coreA", 0.0);
    assert(controller.tick(30.0) == Strings{"coreA=shutdown"});
}

static void failedRestartIsConsumedAndNeedsANewRequest() {
    OverheatPreventionController controller(2.0, 0.0, {"coreA"});

    controller.setCoreLoad(0.0, "coreA", 102.0);
    assert(controller.tick(0.0) == Strings{"coreA=cooling"});
    assert(controller.tick(30.0) == Strings{"coreA=shutdown"});

    // At t=31 the core is still far above 50 C, so this request fails.
    controller.setCoreLoad(30.5, "coreA", 10.0);
    assert(controller.tick(31.0) == Strings{});

    // Passive cooling eventually takes it below 50 C, but the failed request
    // was one-shot, so it remains shut down.
    assert(controller.tick(534.0) == Strings{});

    assert(controller.tick(535.0) == Strings{}); assert(controller.tick(785.0) == Strings{}); controller.setCoreLoad(785.5, "coreA", 10.0); assert(controller.tick(786.0) == Strings{"coreA=idle"});
}

static void vibrationPenaltyCanCauseACascade() {
    OverheatPreventionController controller(
        77.0, 30.0, {"coreB", "coreA"});

    controller.setCoreLoad(0.0, "coreA", 100.0);
    controller.setCoreLoad(0.0, "coreB", 50.0);

    // With no active cores:
    //   total demand = 102 + 52 = 154
    //   coreA passive share = 51 W -> uncooled net heat = 49 W, so A needs it
    //   coreB passive share = 26 W -> uncooled net heat = 24 W, so B does not
    // After A is cooled, vibration reduces passive capacity to 69.3 W:
    //   coreB passive share = 23.4 W -> uncooled net heat = 26.6 W
    //   0.02 * 26.6 = 0.532 C/s, so B now also needs active cooling.
    // The result is sorted alphabetically even though IDs were passed as B, A.
    assert(controller.tick(0.0) ==
           (Strings{"coreA=cooling", "coreB=cooling"}));
}

int main() {
    pendingLoadIsDelayedAndLatestRequestWins();
    oldLoadControlsTheIntervalThatJustEnded();
    failedRestartIsConsumedAndNeedsANewRequest();
    vibrationPenaltyCanCauseACascade();

    std::cout << "All overheat controller tests passed.\n";
}
