# RV32I 5-Stage Pipelined RISC-V CPU (SystemVerilog)

A 5-stage pipelined RV32I core (IF/ID/EX/MEM/WB), built on top of the same functional building blocks as the companion single-cycle and multicycle implementations. `pipeline_top.sv` is wired together and passes a full integration test — see [Status](#status) for exactly what's covered and what's still ahead.

## Overview

Unlike the multicycle design (one shared ALU/memory, one instruction in flight at a time, sequenced by an FSM), this pipeline runs every stage every cycle, with up to five instructions in flight simultaneously. That means:

- Control signals are decoded once, combinationally, in ID — there's no FSM.
- Data hazards (an instruction needing a value that hasn't been written back yet) are handled by forwarding where possible and stalling only when forwarding can't help (load-use).
- Control hazards (branches, jumps) are handled by resolving in EX and flushing the wrong-path instructions already fetched.

## Module List

### Reused unchanged from the single-cycle / multicycle repos
`alu.sv`, `alu_control.sv`, `alu_src_mux.sv`, `decoder.sv`, `imm_generator.sv`, `branch_comparator.sv`, `data_mem.sv`, `writeback_mux.sv`, `pc.sv`, `instr_mem.sv`, `riscv_pkg.sv` — none of these know or care whether they're sitting in a multicycle FSM or a pipeline stage; they take inputs, produce outputs, same cycle either way.

### Modified from the earlier repos
| Module | Change |
|---|---|
| `register_file.sv` | Added a write-first same-cycle read bypass at `read_data1`/`read_data2`. WB and ID can now target the same register in the same cycle (an instruction two stages ahead writing back while a later instruction reads) — without this, that read would return the stale pre-write value. |

### New, pipeline-specific
| Module | Responsibility |
|---|---|
| `id_control_unit.sv` | Combinational control decode from opcode — replaces the multicycle FSM's per-state signal assignments. Tested against all 9 opcode classes plus the default case in `TB/id_control_unit_tb.sv`. |
| `if_id_reg.sv` | IF/ID pipeline register. Supports `stall` (freeze, hold current instruction) and `flush` (squash to a no-op on a taken branch/jump). |
| `id_ex_reg.sv` | ID/EX pipeline register. Carries both datapath values and control signals forward; supports `bubble` (force to a no-op) for load-use stalls and for the second half of a branch/jump flush. |
| `ex_mem_reg.sv` | EX/MEM pipeline register. No stall/flush input — once an instruction resolves in EX it's committed and always moves forward. |
| `mem_wb_reg.sv` | MEM/WB pipeline register. |
| `hazard_detection_unit.sv` | Detects load-use hazards: compares ID stage's `rs1`/`rs2` against EX stage's `rd` when EX holds a load. Unit-tested in `TB/hazard_fwd_tb.sv`. |
| `forwarding_unit.sv` | Selects EX/MEM or MEM/WB as the forwarding source for the EX stage's ALU operands, prioritizing the more recent (EX/MEM) result. Unit-tested in `TB/hazard_fwd_tb.sv`. |
| `pipeline_top.sv` | Wires all of the above into the full 5-stage pipeline. Passes a 16-check integration test covering forwarding, load-use stalling, and branch/jump flushing — see [Simulation](#simulation). |

## Design Notes

### No `old_pc` needed here

The multicycle design needed a dedicated `old_pc` latch because its `FETCH` state speculatively incremented the live `pc` register before the fetched instruction had even been decoded — by the time later states ran, `pc` no longer matched that instruction's own address.

That problem doesn't exist in this design. `IF/ID`'s `pc` field is captured exactly once, the cycle an instruction is fetched, and is never touched again as that instruction moves through `ID/EX` and beyond. It's already what `old_pc` was standing in for. `id_control_unit.sv` uses `ALU_SRC_PC` directly for `AUIPC`/`JAL`/`BRANCH` — no `ALU_SRC_OLD_PC` needed anywhere in this design.

### Branch target reuses the shared ALU, not a dedicated adder

The earlier single-cycle design computed branch targets with its own dedicated adder in `next_pc_logic.sv`, so its `BRANCH` control signals set `alu_src_a_sel`/`alu_src_b_sel` to `RS1`/`RS2` (the ALU's output for `BRANCH` was unused). This pipeline has no such dedicated adder — `BRANCH` instead sets `ALU_SRC_PC`/`ALU_SRC_IMM`, so the shared ALU computes `pc + imm` as the target, the same way the multicycle design's `EXEC_BRANCH` state did. `branch_comparator.sv` still gets the real `rs1`/`rs2` comparison values through its own independent ports, untouched by this.

### A taken branch/jump flushes two pipeline registers, not one

By the time a branch/jump resolves in EX, two younger instructions have already entered the pipeline on the (possibly wrong) sequential path: one currently in `IF/ID`, and one that finished decoding this same cycle and would otherwise land in `ID/EX` next cycle. `flush_ex` in `pipeline_top.sv` therefore drives both `if_id_reg`'s `flush` input and `id_ex_reg`'s `bubble` input (`bubble_hazard || flush_ex`) — squashing only one of the two would let a wrong-path instruction slip through.

## Known Limitations

- Byte/halfword load-store (LB/LH/LBU/LHU/SB/SH) still unimplemented, inherited from the earlier designs.
- No branch prediction yet — current plan is predict-not-taken to start, with the flush mechanism already built to support it.
- No exception/CSR support yet.
- The integration test does not yet cover a branch whose own comparison operands need forwarding (e.g. `add x1,...` immediately followed by `beq x1,...`). Forwarding into the ALU is tested; forwarding into `branch_comparator` specifically is not yet exercised by a dedicated test case.

## Simulation

Tested with Icarus Verilog (`iverilog` / `vvp`).

```bash
iverilog -g2012 -o sim.out riscv_pkg.sv pc.sv instr_mem.sv decoder.sv register_file.sv \
  imm_generator.sv alu_src_mux.sv alu.sv alu_control.sv branch_comparator.sv data_mem.sv \
  writeback_mux.sv if_id_reg.sv id_ex_reg.sv ex_mem_reg.sv mem_wb_reg.sv \
  hazard_detection_unit.sv forwarding_unit.sv id_control_unit.sv pipeline_top.sv \
  TB/pipeline_top_tb.sv
vvp sim.out
iverilog -g2012 -o sim.out riscv_pkg.sv id_control_unit.sv TB/id_control_unit_tb.sv
vvp sim.out
iverilog -g2012 -o sim.out hazard_detection_unit.sv forwarding_unit.sv TB/hazard_fwd_tb.sv
vvp sim.out
```

## Status

- [x] ID-stage combinational control decode (`id_control_unit.sv`) — tested
- [x] Four pipeline registers (`if_id_reg.sv`, `id_ex_reg.sv`, `ex_mem_reg.sv`, `mem_wb_reg.sv`) — integration-tested via `pipeline_top.sv`
- [x] Load-use hazard detection (`hazard_detection_unit.sv`) — tested
- [x] EX-stage forwarding source selection (`forwarding_unit.sv`) — tested
- [x] `register_file.sv` write-first same-cycle read fix
- [x] `pipeline_top.sv` — wired together, passes a 16-check integration test
- [ ] Branch-operand forwarding test case (see Known Limitations)
- [ ] Byte/halfword load-store
- [ ] Branch prediction (predict-not-taken to start)
- [ ] Exception/CSR support
