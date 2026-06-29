# Citadel / Jane Street Hardware Interview Curriculum

Last updated: 2026-06-25

Purpose: keep a compact, living record of what has been reviewed in this folder, what is solid, what needs another pass, and what to practice next. This file is meant to save rereading every problem from scratch every time.

## Current Snapshot

Target roles:
- Citadel / Citadel Securities style: FPGA, low-latency RTL, timing, CDC, FIFOs, BRAM, C/C++ coding.
- Jane Street style: clean hardware architecture, testing discipline, tooling mindset, first-principles reasoning, RTL/HCL fluency.

Current prep signal:
- LeetCode base: about 125 solved, with most work in easy/medium patterns.
- Current RTL focus: LogiCode/SystemVerilog practice problems.
- Current folder inventory: `skip3.sv`, `binary_to_thermometer_decoder.sv`.
- Immediate theme: stop at exact cycle behavior before writing code. Define valid timing, reset behavior, latency, throughput, and boundary cases.

Verified reference points:
- SystemVerilog is the IEEE 1800 language for unified hardware design, specification, and verification. IEEE 1800-2023 covers behavioral, RTL, and gate-level modeling plus testbenches, coverage, assertions, OOP, constrained-random verification, and foreign-language APIs: https://standards.ieee.org/ieee/1800/7743/
- Accellera lists IEEE 1800-2023 as the current SystemVerilog standard and makes it available through the IEEE Get program: https://www.accellera.org/downloads/ieee
- Google Benchmark is a C++ microbenchmark library. Use it for C++ golden models and CPU baselines, not for RTL cycle/Fmax measurement: https://github.com/google/benchmark
- LogiCode problem source: https://logi-code.com/problems

Important conclusion: being stronger in SystemVerilog than old Verilog is fine, but interviews may still use plain Verilog snippets. Practice mentally translating `reg`, `wire`, `always @(*)`, and `always @(posedge clk)` into the equivalent SV intent.

## Review Tags

Use these tags in the problem log:

- `cycle-semantics`: exact behavior per clock edge is unclear or wrong.
- `valid-timing`: valid/data alignment, idle valid behavior, or backpressure needs review.
- `reset`: reset style, reset coverage, or post-reset outputs need review.
- `off-by-one`: terminal count, pointer wrap, or boundary condition risk.
- `synth`: synthesis/resource inference needs review.
- `testbench`: needs self-checking simulation or more edge cases.
- `explain`: needs a crisp 60-90 second verbal explanation.
- `verilog-fluency`: old-style Verilog syntax or snippet-reading practice needed.

## Problem Log

| Date | File | Source / Problem | Status | Notes | Review Tags |
| --- | --- | --- | --- | --- | --- |
| 2026-06-25 | `skip3.sv` | LogiCode style: count/pass values while skipping every 3rd valid input | Reviewed, not yet fully verified | Uses a 2-bit phase counter and nonblocking sequential logic. Good core idea. Needs a testbench with gaps in `valid_in`, signed values, and reset midstream. Current code leaves `valid_out` unchanged when `valid_in` is 0, which likely creates stale valid cycles unless the spec says output only matters during input-valid cycles. | `cycle-semantics`, `valid-timing`, `testbench`, `explain` |
| 2026-06-25 | `binary_to_thermometer_decoder.sv` | LogiCode: Binary to Thermometer Decoder | Reviewed and syntax-checked | Original idea was close, but variable replication like `{din{1'b1}}` is not the right construct for runtime `din`; implemented combinational loop that sets `dout[i] = (i < din)`. Need confirm whether judge expects LSB-side ones or MSB-side ones. | `cycle-semantics`, `synth`, `explain` |

## Skill Rubric

For every module you write, be able to answer these quickly:

- What state is stored?
- What is combinational?
- What updates only on the clock edge?
- What is the latency?
- What is the initiation interval / throughput?
- What happens on reset?
- What happens when input valid is low?
- What happens under backpressure?
- What resource does this likely infer?
- How would I test it?

## Core Curriculum

### Track 1: RTL Timing And Small Blocks

Goal: make small modules boringly correct.

Practice order:
1. Edge detector.
2. Two-flop synchronizer.
3. Enable pulse every N cycles.
4. Fixed-priority arbiter.
5. Sequence detector with overlap.
6. Pipelined adder/multiplier with valid tracking.

Need cold:
- `always_comb` default assignments avoid latches.
- `always_ff` state updates use nonblocking assignments.
- Data and valid must move through the same number of stages.
- Every output valid pulse needs an exact cycle meaning.

### Track 2: Ready/Valid And Backpressure

Goal: speak transfer semantics cleanly.

Practice order:
1. One-stage ready/valid pipeline register.
2. One-element buffer.
3. Skid buffer.
4. Ready/valid FIFO.

Need cold:
- Transfer occurs when `valid && ready`.
- If downstream stalls, data and valid must remain stable.
- If input and output fire in the same cycle, define whether the slot is replaced, bypassed, or held.

### Track 3: FIFOs

Goal: make FIFO questions feel routine.

Practice order:
1. Single-clock FIFO using `count`.
2. Single-clock FIFO using pointer wrap bit.
3. FIFO with ready/valid interface.
4. FIFO with almost-full / almost-empty.
5. Async FIFO explanation and pointer logic.

Need cold:
- Empty: occupancy is 0.
- Full: occupancy is DEPTH.
- Simultaneous read/write changes occupancy only at boundaries if you choose conservative behavior.
- Pointer lower bits alone cannot distinguish full from empty.
- Registered-output FIFO and first-word fall-through FIFO have different cycle behavior.

### Track 4: CDC

Goal: never sample cross-domain control/data casually.

Practice order:
1. Two-flop synchronizer for single-bit level.
2. Synchronize then edge-detect an async signal.
3. Pulse synchronizer.
4. Gray-code pointer transfer.
5. Async FIFO full/empty derivation.

Need cold:
- Multi-bit CDC is unsafe unless encoded/protocol-protected.
- Gray code helps because only one bit changes per increment.
- Each pointer is generated in its own clock domain and synchronized before cross-domain comparison.

### Track 5: FPGA Resources

Goal: connect RTL to actual FPGA fabric.

Practice order:
1. Sync ROM with 1-cycle read latency.
2. Simple dual-port RAM.
3. True dual-port RAM.
4. LUTRAM vs BRAM version.
5. Memory replication for extra reads.
6. Banked memory access pattern.

Need cold:
- LUTs implement combinational logic and small distributed RAM.
- FFs implement scalar state and pipeline registers.
- BRAM is usually synchronous and has defined read-during-write modes.
- DSP blocks handle multiply/MAC patterns.
- Carry chains are fast for add/sub/compare.
- Routing can dominate timing, especially at high utilization.

### Track 6: C/C++ And Google Benchmark

Goal: keep low-level coding sharp without pretending it measures RTL.

Practice order:
1. Bit parser.
2. Ring buffer.
3. Packed struct decoder.
4. Endianness conversion.
5. Fixed-point arithmetic helper.
6. Google Benchmark for one C++ golden-model routine.

Need cold:
- `benchmark::DoNotOptimize` and `benchmark::ClobberMemory`.
- `Arg`, `Range`, `DenseRange`, and `state.range(0)`.
- `SetItemsProcessed` / `SetBytesProcessed`.
- JSON/CSV benchmark output for comparing variants.
- RTL performance is measured in cycles/input, latency, initiation interval, Fmax, and resources.

### Track 7: Project Proof

Goal: make projects interview evidence, not just files.

Artifacts to build:
- Block diagram.
- Pipeline timing diagram.
- Latency table by stage.
- Utilization report: LUT / FF / BRAM / DSP.
- Timing report: target clock, WNS, TNS.
- Simulation testbench.
- C++ golden model.
- Trace comparison between RTL and C++.
- Measured throughput and known accuracy/error bound.

## Next Practice Queue

1. Add a self-checking testbench for `skip3.sv`.
2. Decide whether `valid_out` should go low whenever `valid_in` is low. If yes, fix `skip3.sv`.
3. Write `edge_detect.sv`.
4. Write `sync_2ff.sv`.
5. Write `fixed_priority_arbiter.sv`.
6. Write `rv_pipeline_reg.sv`.
7. Write `skid_buffer.sv`.
8. Write `fifo_sync_count.sv`.

## 90-Second Explanation Template

Use this before code and after code:

1. State the interface behavior in cycle terms.
2. Name the state registers.
3. Name the combinational decisions.
4. Walk reset.
5. Walk normal transfer.
6. Walk boundary cases.
7. State latency and throughput.
8. State the highest-risk bug and how the testbench catches it.

## Update Protocol

When new files are added:

1. Add one row to `Problem Log`.
2. Mark status as `New`, `Reviewed`, `Verified`, or `Needs rework`.
3. Add review tags.
4. Add the next focused drill if the same tag repeats three times.
5. Keep this file concise. Detailed notes should live next to the problem or in the testbench.
