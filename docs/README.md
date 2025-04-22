# tiny OoO CPU

## Description

This project implements a small Out-of-Order (OoO) CPU capable of issuing, executing, and committing instructions using a modern pipeline structure. It supports basic ALU operations (ADD, SUB, AND, OR, XOR), memory load/store operations (LD, STR), and HALT.

The processor consists of:

- An **Instruction Queue (IQ)** to buffer incoming instructions.
- An **ALU Reservation Station** with 2 entries for out-of-order execution.
- A **Register Alias Table (RAT)** for register renaming.
- A **Reorder Buffer (ROB)** to ensure in-order commit and precise exceptions.
- A **Register File (RF)** and **Memory Unit** for execution.

For full design details and architecture overview, see `docs/description.pdf`.

## IO Specification

| Input/Output   | Width   | Description                                |
| -------------- | ------- | ------------------------------------------ |
| `io_in[11:0]`  | 12 bits | 12-bit instruction input (1 per cycle)     |
| `clock`        | 1 bit   | System clock (30MHz required)              |
| `reset`        | 1 bit   | Active-high synchronous reset              |
| `io_out[11:6]` | 6 bits  | Final cycle count                          |
| `io_out[5:3]`  | 3 bits  | Output register index (0 to 7)             |
| `io_out[2:0]`  | 3 bits  | Value stored in the register being printed |

## Instruction Format

- `000`: ADD
- `001`: SUB
- `010`: AND
- `011`: OR
- `100`: XOR
- `101`: LD
- `110`: STR
- `111`: HALT

## Execution Behavior

- The CPU fetches and decodes one instruction per cycle.
- Instructions are issued into either the ALU or Memory reservation station.
- Instructions execute when operands are ready.
- Results are committed in program order via the ROB.
- When execution is done, the final cycle count is frozen.
- After execution is done, `io_out[5:0]` outputs the 8 register values over 8 cycles.

## How to Test

1. Apply reset high for a few cycles, then deassert.
2. Feed 12-bit instructions into `io_in` at 1 instruction per cycle.
3. Wait for the execution to finish.
4. Observe `io_out`:
   - `io_out[11:6]`: final cycle count.
   - `io_out[5:3]`: register index being printed (0 to 7).
   - `io_out[2:0]`: value in that register.

## Test Considerations

- **ALU and MEM update limitation**: The design only allows **one update per cycle** from either the ALU or Memory unit.  
  If **both ALU and Memory complete in the same cycle**, only **one of them will be updated in the reorder buffer**.  
  Therefore, test programs should avoid scheduling simultaneous ALU and MEM completions to ensure correct execution.

- For additional implementation details and timing diagrams, please refer to the documentation in `docs/description.pdf`.
