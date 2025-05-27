# Architecture Documentation

## Overview

This document provides detailed technical information about the divide-by-3 clock divider architecture, implementation details, and design decisions.

## System Architecture

### High-Level Block Diagram

```
                    ┌─────────────────────────────────────┐
                    │        Divide-by-3 Module          │
                    │                                     │
    clk ────────────┼──┬─────────────────┬────────────────┼──────► y
                    │  │                 │                │   (f_clk/3)
    rst ────────────┼──┼─────────────────┼────────────────┤
                    │  │                 │                │
                    │  ▼                 ▼                │
                    │ ┌─────────────┐  ┌─────────────┐    │
                    │ │  Counter 1  │  │  Counter 2  │    │
                    │ │ (pos edge)  │  │ (neg edge)  │    │
                    │ │    FSM      │  │    FSM      │    │
                    │ └──────┬──────┘  └──────┬──────┘    │
                    │        │                │           │
                    │        ▼                ▼           │
                    │     out_1           out_2           │
                    │        │                │           │
                    │        └────────┬───────┘           │
                    │                 ▼                   │
                    │            ┌─────────┐              │
                    │            │ OR Gate │              │
                    │            └─────────┘              │
                    └─────────────────────────────────────┘
```

## Finite State Machine Design

### State Encoding

Both counters implement identical 3-state finite state machines:

| State | Binary | Decimal | Description |
|-------|--------|---------|-------------|
| S0    | 2'b00  | 0       | Initial state |
| S1    | 2'b01  | 1       | Intermediate state |
| S2    | 2'b10  | 2       | Output state (generates pulse) |

### State Transition Diagram

```
        ┌─────┐
        │ S0  │
        │(00) │◄──────────┐
        └──┬──┘           │
           │              │
           ▼              │
        ┌─────┐           │
        │ S1  │           │
        │(01) │           │
        └──┬──┘           │
           │              │
           ▼              │
        ┌─────┐           │
        │ S2  │───────────┘
        │(10) │ output=1
        └─────┘
```

**Transition Logic:**
- S0 → S1 (always)
- S1 → S2 (always)  
- S2 → S0 (always, with output pulse)

## Dual Counter Architecture

### Counter 1: Positive Edge Triggered
- **Clock**: Rising edge of input clock
- **Reset State**: S0 (2'b00)
- **Operation**: Standard mod-3 counter
- **Output**: High when in state S2

### Counter 2: Negative Edge Triggered  
- **Clock**: Falling edge of input clock
- **Reset State**: S1 (2'b01) - **Key difference!**
- **Operation**: Identical mod-3 counter, but phase-shifted
- **Output**: High when in state S2

### Phase Offset Strategy

The key to achieving 50% duty cycle is the **initial state offset**:

1. **Counter 1** starts at state S0
2. **Counter 2** starts at state S1  

This creates a **180° phase shift** between the two counters, ensuring that when one counter's output is low, the other provides the high output.

## Timing Analysis

### Clock Domain Analysis

| Signal | Clock Domain | Edge | Notes |
|--------|-------------|------|-------|
| current_state_1 | clk | Rising | Main counter |
| current_state_2 | clk | Falling | Phase-shifted counter |
| out_1, out_2 | clk | Both | Combinational outputs |
| y | clk | Both | Final OR output |

### Critical Timing Paths

1. **Setup Time Path**: next_state → current_state (both counters)
2. **Combinational Path**: current_state → out_1/out_2 → y
3. **Reset Path**: rst → current_state (synchronous)

## Resource Utilization

### Flip-Flops
- **Counter 1 State**: 2 flip-flops (current_state_1[1:0])
- **Counter 2 State**: 2 flip-flops (current_state_2[1:0])
- **Total**: 4 flip-flops

### Combinational Logic
- **Next State Logic**: 2 × 2-bit multiplexers (one per counter)
- **Output Logic**: 2 × AND gates + 1 × OR gate
- **Total LUTs**: ~6-8 LUTs (depending on optimization)

### Routing Resources
- **Clock Networks**: 1 (both pos/neg edges of same clock)
- **Reset Network**: 1 (synchronous reset to all flip-flops)

## Design Trade-offs

### Advantages
1. **Exact 50% Duty Cycle**: Achieved through dual counter approach
2. **Low Resource Usage**: Only 4 flip-flops required
3. **Synchronous Design**: Single clock domain with pos/neg edges
4. **Scalable**: Architecture can be extended to other divide ratios

### Limitations  
1. **Clock Loading**: Both edges of input clock are used
2. **Skew Sensitivity**: Pos/neg edge timing must be balanced
3. **Fixed Ratio**: Hardcoded for divide-by-3 operation
4. **Reset Dependency**: Requires proper reset sequencing

## Alternative Architectures Considered

### 1. Single Counter with Logic
```
Counter: 0→1→2→0→1→2→...
Output Logic: (count == 1) OR (count == 2)
Result: 66.7% duty cycle ❌
```

### 2. Ripple Counter Approach
```
3-bit counter with decode logic
Result: Higher resource usage, timing issues ❌
```

### 3. PLL-Based Solution
```
Use PLL to generate 3× clock, then divide
Result: Higher complexity, external components ❌
```

**Conclusion**: The dual counter approach provides the optimal balance of simplicity, resource efficiency, and precise timing control.

## Verification Strategy

### Functional Verification
- State machine transitions
- Reset behavior  
- Output generation logic
- Edge case handling

### Timing Verification
- Setup/hold time analysis
- Clock skew tolerance
- Propagation delay measurement
- Duty cycle accuracy

### Coverage Metrics
- State coverage: All states visited
- Transition coverage: All transitions exercised  
- Edge coverage: Both clock edges tested
- Reset coverage: Reset in all states

## Implementation Notes

### Synthesis Considerations
- Ensure both clock edges are properly handled
- Verify reset synchronization
- Check for unwanted latches in combinational logic
- Optimize for target FPGA architecture

### Physical Implementation
- Balance clock tree for both edges
- Minimize skew between counters
- Place related logic close together
- Consider power optimization

## Future Enhancements

### Parameterization
- Configurable divide ratio
- Selectable duty cycle
- Optional enable signal

### Advanced Features  
- Fractional division support
- Multiple output phases
- Built-in frequency measurement
- Dynamic ratio adjustment