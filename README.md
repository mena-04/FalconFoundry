# PICO-Softmax

PICO-Softmax is a compact fixed-point Softmax hardware accelerator developed for transformer inference. The design implements a hardware-efficient Base-2 Softmax using fixed-point arithmetic, LUT-based exponentiation, and serial normalization.

---

## Features

- 8-element Softmax accelerator
- Signed 8-bit Q3.4 input format
- Unsigned 8-bit Q0.8 output format
- Base-2 exponential approximation
- Hybrid exponentiation using:
  - Integer right shifts
  - Fractional lookup table (LUT)
- Serial shift-subtract fractional divider
- FSM-controlled sequential datapath
- Modular RTL architecture
- Python golden reference model

---

## Architecture

The accelerator consists of the following modules:

- Bus Interface
- Input Vector Buffer
- Controller (FSM)
- Max Finder
- Delta Unit
- Exp2 Hybrid Unit
- Exponent Buffer
- Denominator Accumulator
- Serial Fractional Divider
- Output Buffer

### Processing Flow

```
Input
  ↓
Bus Interface
  ↓
Input Buffer
  ↓
Max Finder
  ↓
Delta Unit
  ↓
Exp2 Hybrid Unit
  ↓
Exponent Buffer
  ↓
Denominator Accumulator
  ↓
Serial Fractional Divider
  ↓
Output Buffer
```

---

## Repository Structure

```
docs/
    schematic.pdf
    waveform.png
    waveform_test1.png
    waveform_test2.png
    waveform_test3.png
    waveform_test4.png
    waveform_test5.png
    waveform_test6.png
    Tcl_console.txt

rtl/
    pico_softmax_top.v
    pico_softmax_controller.v
    pico_softmax_bus_if.v
    max_finder.v
    delta_unit.v
    exp2_frac_lut.v
    exp2_shift_unit.v
    exp2_hybrid_unit.v
    exp_buffer.v
    denominator_accumulator.v
    serial_fractional_divider.v
    input_vector_buffer.v
    output_buffer.v
    index_counter.v
    softmax_params.vh

testbench/
    tb_pico_softmax.v
    tb_delta_unit.v
    tb_exp2_frac_lut.v
    tb_exp2_shift_unit.v
    tb_exp2_hybrid_unit.v
    tb_max_finder.v
```

---

# Verification

The RTL implementation was verified using **AMD Vivado XSIM** and compared against Python reference models.

## RTL vs Fixed-Point Python Golden Model

The Verilog implementation was verified against a bit-accurate fixed-point Python model implementing the same hardware datapath.

Verification Summary

| Metric | Result |
|-------|-------:|
| Total Tests | 6 |
| Passed | 6 |
| Failed | 0 |
| Maximum RTL Error | **0 LSB** |
| Overall Result | **PASS** |

All RTL outputs matched the fixed-point Python golden model exactly for the directed verification test vectors.

---

## RTL vs Floating-Point Base-2 Softmax

The fixed-point RTL outputs were also compared against an ideal floating-point Base-2 Softmax implementation to evaluate numerical accuracy.

| Metric | Result |
|-------|-------:|
| Mean Absolute Error | **0.00138346** |
| Maximum Absolute Error | **0.00350116** |
| Top-1 Match Rate | **100%** |
| Mean RTL Output Sum | **0.98893229** |

These results demonstrate that the hardware-friendly fixed-point implementation closely approximates the floating-point Base-2 Softmax while preserving the correct Top-1 prediction for all evaluated test vectors.

---

## Simulation

Behavioral simulation was performed using:

- AMD Vivado 2026.1
- XSIM Simulator

Simulation artifacts included:

- Top-level RTL simulation
- Waveform verification
- Directed test vectors
- Python golden model comparison

The complete simulation transcript is available in:

```
docs/Tcl_console.txt
```

Representative simulation waveforms are provided in:

```
docs/
```

---

## Tools

- Verilog HDL
- AMD Vivado 2026.1
- XSIM Simulator
- Python
- NumPy

---

## Authors

Developed as part of the Chipathon project.
