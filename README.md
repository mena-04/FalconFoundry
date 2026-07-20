# PICO-Softmax

PICO-Softmax is a compact fixed-point Softmax hardware accelerator designed for transformer inference. The accelerator implements a hardware-efficient Base-2 Softmax using fixed-point arithmetic, hybrid LUT/shift exponentiation, and serial normalization to reduce hardware complexity while maintaining numerical accuracy.

---

# Features

- 8-element Softmax accelerator
- Signed 8-bit Q3.4 input format
- Unsigned 8-bit Q0.8 output format
- Base-2 exponential approximation
- Hybrid exponentiation using:
  - Integer right shifts
  - Fractional lookup table (LUT)
- Serial shift-subtract fixed-point divider
- FSM-controlled sequential datapath
- Modular RTL architecture
- Python fixed-point golden reference model
- Top-level RTL verification using AMD Vivado XSIM

---

# Architecture

The accelerator consists of the following RTL modules:

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

## Processing Flow

```text
Input
  ↓
Bus Interface
  ↓
Input Vector Buffer
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

# Repository Structure

```text
docs/
│
├── schematic.pdf
│
└── integration_verification/
    ├── Tcl_console.txt
    ├── tb_pico_softmax.wcfg
    ├── waveform.png
    ├── waveform_test1.png
    ├── waveform_test2.png
    ├── waveform_test3.png
    ├── waveform_test4.png
    ├── waveform_test5.png
    └── waveform_test6.png

rtl/
│
├── pico_softmax_top.v
├── pico_softmax_controller.v
├── pico_softmax_bus_if.v
├── input_vector_buffer.v
├── output_buffer.v
├── exp_buffer.v
├── max_finder.v
├── delta_unit.v
├── exp2_frac_lut.v
├── exp2_shift_unit.v
├── exp2_hybrid_unit.v
├── denominator_accumulator.v
├── serial_fractional_divider.v
├── index_counter.v
└── softmax_params.vh

testbench/
│
├── tb_pico_softmax.v
├── tb_pico_softmax_bus_if.v
├── tb_pico_softmax_controller.v
├── tb_delta_unit.v
├── tb_denominator_accumulator.v
├── tb_exp2_frac_lut.v
├── tb_exp2_hybrid_unit.v
├── tb_exp2_shift_unit.v
├── tb_exp_buffer.v
├── tb_input_vector_buffer.v
├── tb_max_finder.v
├── tb_output_buffer.v
└── tb_serial_fractional_divider.v

PICO_Softmax.ipynb
PICO_Softmax.py

FP_Softmax.ipynb
FP_Softmax.py

```

---

# Verification

Verification was performed using **AMD Vivado XSIM** together with Python reference models.

## RTL vs Fixed-Point Python Golden Model

The Verilog RTL was verified against a bit-accurate Python fixed-point golden model implementing the same Base-2 Softmax datapath.

### Verification Results

| Metric | Result |
|---------|:------:|
| Directed Test Cases | 6 |
| Tests Passed | **6 / 6** |
| Maximum RTL Error | **0 LSB** |
| Overall Result | **PASS** |

The following directed verification cases were executed:

- All Equal Inputs
- Increasing Inputs
- Decreasing Inputs
- Negative Inputs
- Mixed Positive/Negative Inputs
- Dominant Input Value

All RTL outputs matched the Python fixed-point golden model exactly.

---

## RTL vs Floating-Point Base-2 Softmax

The fixed-point RTL outputs were compared against the floating-point Base-2 Softmax reference implementation.

| Metric | Result |
|---------|:------:|
| Mean Absolute Error | **0.00138346** |
| Maximum Absolute Error | **0.00350116** |
| Top-1 Match Rate | **100%** |
| Mean RTL Output Sum | **0.98893229** |

These results demonstrate that the hardware-friendly fixed-point implementation closely approximates the floating-point Base-2 Softmax while preserving the correct Top-1 prediction.

---

# Verification Artifacts

Project documentation and verification evidence are located in the **docs/** directory.

The **docs/integration_verification/** directory contains the top-level system verification artifacts, including:

- Vivado XSIM simulation waveform screenshots
- Complete Tcl simulation transcript
- Top-level integration verification results

Additional module-level verification artifacts may be added as development progresses.

---

# Development Tools

- Verilog HDL
- AMD Vivado Design Suite 2026.1
- XSIM Simulator
- Python 3
- NumPy

---

# Authors

Developed as part of the **Chipathon** project.
