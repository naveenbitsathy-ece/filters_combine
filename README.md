# FPGA-Based Selectable FIR Filter System Using MATLAB and ZedBoard

A digital signal processing project to implement four selectable Finite Impulse Response (FIR) filters in the programmable logic (PL) of a Xilinx ZedBoard (Zynq-7000 SoC). MATLAB generates and sends input samples to the board, the FPGA applies the selected filter, and MATLAB receives and analyzes the filtered output.

The planned filter modes are **Low-Pass, High-Pass, Band-Pass, and Band-Stop**. A filter-selection value sent from MATLAB determines which filter output is returned.

> **Project status:** Architecture and RTL selection concept are being developed. Update this README with measured results after the four FIR filters, UART integration, and hardware verification are completed. The current threshold-comparison RTL is not yet a true FIR implementation.

---

## Table of Contents

- [1. Project Overview](#1-project-overview)
- [2. Objectives](#2-objectives)
- [3. Hardware and Software Requirements](#3-hardware-and-software-requirements)
- [4. System Architecture](#4-system-architecture)
- [5. How the Project Works](#5-how-the-project-works)
- [6. FIR Filter Theory](#6-fir-filter-theory)
- [7. Filter Modes and Selection](#7-filter-modes-and-selection)
- [8. MATLAB Input Signal](#8-matlab-input-signal)
- [9. Hardware and Software Interface](#9-hardware-and-software-interface)
- [10. UART Protocol](#10-uart-protocol)
- [11. Recommended Project Structure](#11-recommended-project-structure)
- [12. Implementation Procedure](#12-implementation-procedure)
- [13. Verification and Result Analysis](#13-verification-and-result-analysis)
- [14. Troubleshooting](#14-troubleshooting)
- [15. Applications](#15-applications)
- [16. Future Improvements](#16-future-improvements)
- [17. Author](#17-author)

---

## 1. Project Overview

Digital filters are used to retain desired frequency components and attenuate unwanted components in sampled signals. This project aims to implement four FIR filter responses in FPGA programmable logic and select the desired response through a control value from MATLAB.

The intended system uses MATLAB for signal generation and reference calculations, UART for communication with the ZedBoard, the Zynq Processing System (PS) for embedded control, AXI GPIO for transferring samples and control signals, and custom Verilog RTL in the PL for filtering.

### Planned Features

- MATLAB-based input-signal generation.
- Four selectable FIR responses:
  - Low-Pass Filter (LPF)
  - High-Pass Filter (HPF)
  - Band-Pass Filter (BPF)
  - Band-Stop Filter (BSF)
- Filter selection controlled by MATLAB.
- Verilog RTL implementation in FPGA programmable logic.
- MATLAB-to-ZedBoard UART communication.
- Zynq PS-to-PL communication through AXI GPIO.
- Comparison against MATLAB reference-filter outputs.
- Waveform and numerical error analysis.
- Future analysis of FPGA utilization, timing, and power.

---

## 2. Objectives

1. Understand the design and implementation of FIR filters.
2. Generate test signals in MATLAB.
3. Design LPF, HPF, BPF, and BSF coefficient sets.
4. Implement the filter datapaths in Verilog HDL.
5. Select a filter mode through a control input.
6. Transfer samples and control information between MATLAB and the ZedBoard.
7. Compare FPGA results with MATLAB reference outputs.
8. Verify functional correctness, latency, throughput, and timing.
9. Measure FPGA resource utilization and estimate power after implementation.

---

## 3. Hardware and Software Requirements

### Hardware

| Component | Purpose |
|---|---|
| Xilinx ZedBoard | FPGA development platform |
| Zynq-7000 SoC | ARM processing system and FPGA programmable logic |
| PC or laptop | MATLAB execution and FPGA development |
| USB-UART connection | MATLAB-to-board serial communication |
| USB/JTAG programming connection | FPGA programming and debugging |

### Software

| Software | Purpose |
|---|---|
| MATLAB R2013a | Signal generation, UART communication, reference filtering, plotting |
| Xilinx Vivado | RTL integration, synthesis, implementation, timing analysis, bitstream generation |
| Xilinx Vitis | Embedded C application for UART and AXI GPIO control |
| Verilog HDL | FIR filter RTL |
| C | Processor-side communication and filter-control logic |

### Existing System Configuration

The existing MATLAB-to-ZedBoard workflow has used the following settings. Confirm these against the current hardware design and software before running the system.

| Parameter | Existing configuration |
|---|---|
| FPGA board | ZedBoard (Zynq-7000) |
| Fabric clock | 100 MHz configured clock |
| UART port | COM3 (may vary by computer) |
| UART baud rate | 115200 |
| UART format | 8 data bits, no parity, 1 stop bit |
| Sample representation | 16-bit unsigned integer, low byte first |
| Processor-to-PL interface | AXI GPIO |

---

## 4. System Architecture

### Block Diagram

```text
+--------------------------------------+
|             MATLAB (PC)              |
|                                      |
|  Input Signal Generation             |
|  Filter Mode Selection               |
|  Reference FIR Filtering             |
|  Output Comparison and Plotting      |
+-------------------+------------------+
                    |
                    | UART
                    | Input samples + filter mode
                    v
+--------------------------------------+
|        Zynq Processing System        |
|                                      |
|  ARM Cortex-A9 Processor             |
|  Embedded C Application              |
|  UART Reception / Transmission       |
+-------------------+------------------+
                    |
                    | AXI4-Lite
                    v
+--------------------------------------+
|               AXI GPIO               |
|                                      |
|  Input sample + sample-valid         |
|  Filter selection control            |
|  Filtered output + output-valid      |
+-------------------+------------------+
                    |
                    | Parallel GPIO signals
                    v
+--------------------------------------+
|       FPGA Programmable Logic        |
|                                      |
|  FIR Low-Pass Filter                 |
|  FIR High-Pass Filter                |
|  FIR Band-Pass Filter                |
|  FIR Band-Stop Filter                |
|  Filter Output Selector (MUX)        |
+-------------------+------------------+
                    |
                    | Selected filtered sample
                    v
        AXI GPIO -> ARM -> UART
                    |
                    v
+--------------------------------------+
|             MATLAB (PC)              |
|  Reference Comparison                |
|  Error Calculation                   |
|  Time and Frequency Plots            |
+--------------------------------------+
```

### Main Components

**1. MATLAB**

Generates input samples, chooses the filter mode, sends data, receives the output, calculates reference responses, and visualizes results.

**2. Processing System (PS)**

The ARM Cortex-A9 executes the Vitis C application. It handles UART communication and accesses AXI GPIO.

**3. AXI GPIO**

Transfers input samples, control information, and filtered output between the processor and PL. The exact signal widths and bit assignments must match the Vivado block design, RTL wrapper, and C application.

**4. Programmable Logic (PL)**

Contains the FIR filter datapaths and output-selection logic. The FIR filters must use designed coefficient sets; simple comparisons against sample values do not implement frequency-selective FIR filtering.

---

## 5. How the Project Works

1. **Generate a test signal:** MATLAB creates a useful signal and, where appropriate, adds noise or interference.
2. **Select a filter:** MATLAB chooses LPF, HPF, BPF, or BSF.
3. **Transmit data:** MATLAB sends the filter selection and input samples using the agreed UART protocol.
4. **Receive data in the PS:** The ARM processor reconstructs the samples and control information.
5. **Transfer data to the PL:** The C application writes the sample and control signals through AXI GPIO.
6. **Filter the sample stream:** The selected FIR filter computes the output using its coefficients and sample history.
7. **Return the output:** The PL exposes the filtered sample and a valid indication. The PS reads the result and sends it to MATLAB.
8. **Verify results:** MATLAB compares the received samples with the reference result and plots the input and output.

The RTL and embedded C application must agree on the handshake protocol. The processor should not read or transmit a result until the RTL indicates that it is valid.

---

## 6. FIR Filter Theory

A Finite Impulse Response (FIR) filter calculates its output from the current and a finite number of previous input samples. A standard FIR filter does not use feedback from previous output samples.

For an FIR filter with `N` taps:

\[
y[n] = \sum_{k=0}^{N-1} h[k]x[n-k]
\]

Where:

- `x[n]` is the current input sample.
- `y[n]` is the output sample.
- `h[k]` is the FIR coefficient at index `k`.
- `N` is the number of taps.
- `x[n-k]` is a delayed input sample.

The coefficients determine the filter's frequency response. LPF, HPF, BPF, and BSF filters require different coefficient sets.

### FIR RTL Considerations

- **Coefficient precision:** Determines how accurately the designed coefficients are represented.
- **Input width:** Defines the range of input samples.
- **Product width:** Must accommodate input-by-coefficient multiplication.
- **Accumulator width:** Must accommodate the sum of products without unintended overflow.
- **Rounding and scaling:** Must match the MATLAB fixed-point reference model.
- **Startup behavior:** Initial delay-register contents must be defined, usually as zero.
- **Latency and throughput:** Depend on the architecture, clock, and number of processing stages.

A real FIR filter performs multiply-accumulate operations. A circuit that only tests whether `data_in` is greater or less than a cutoff value is a threshold circuit, not an FIR filter.

---

## 7. Filter Modes and Selection

The proposed design uses a 2-bit `filter_en` signal to choose one of four responses.

| `filter_en` | Mode | Intended frequency response |
|---|---|---|
| `2'b00` | Low-Pass (LPF) | Passes frequencies below the cutoff region |
| `2'b01` | High-Pass (HPF) | Passes frequencies above the cutoff region |
| `2'b10` | Band-Pass (BPF) | Passes a selected frequency band |
| `2'b11` | Band-Stop (BSF) | Attenuates a selected frequency band |

### Filter Descriptions

**Low-Pass FIR**

Passes lower-frequency components and attenuates higher-frequency components. It is useful when the desired signal is relatively low-frequency and the unwanted noise is at higher frequencies.

**High-Pass FIR**

Attenuates lower-frequency components and passes higher-frequency components. It can be used to remove DC offsets or slow variations when those components are not part of the desired signal.

**Band-Pass FIR**

Passes frequencies between a lower and an upper passband edge. It is useful when the desired signal occupies a particular frequency range.

**Band-Stop FIR**

Attenuates a selected frequency range while passing frequencies outside that range. A narrow band-stop filter can be designed to reject interference such as mains-frequency noise, provided the sampling rate and specifications are suitable.

### Selection Architecture

Two architectures are possible:

- **Parallel architecture:** Four FIR datapaths operate in parallel, and a multiplexer selects the output. This is straightforward but can consume more resources.
- **Shared datapath:** One FIR processing datapath uses the coefficient set selected by the mode. This can reduce resource use but requires careful coefficient selection and control.

The initial implementation should prioritize a clear, verifiable architecture. The final choice should be based on measured area, timing, power, and throughput.

**Cutoff frequencies are not normally implemented by comparing the numerical input sample against a cutoff value.** They are reflected in the FIR coefficients designed for the specified sampling rate and frequency response.

---

## 8. MATLAB Input Signal

A useful verification signal should contain frequency components that make the four modes easy to distinguish. For example, a signal can combine a low-frequency sinusoid, a higher-frequency sinusoid, and optional noise.

The following is an illustrative MATLAB R2013a-compatible signal-generation example. Choose frequencies below the Nyquist frequency (`Fs/2`) and adjust them to match the filter specifications.

```matlab
N = 256;
Fs = 1000;

n = 0:N-1;
t = n/Fs;

% Example signal with low- and high-frequency components
x = 1000*sin(2*pi*20*t) ...
  + 500*sin(2*pi*180*t);

% Optional additive noise for testing
% rng(1); % Use only if supported by your MATLAB version
% x = x + 100*randn(size(x));

samples = round(x);
```

This example is for signal-generation planning; the communication protocol and RTL must agree on whether samples are signed or unsigned. The signal above can be negative, so it must not be sent directly as an unsigned magnitude without defining an encoding convention.

### Sampling Considerations

- Sampling frequency: `Fs`.
- Nyquist frequency: `Fs/2`.
- Number of samples: `N`.
- Frequency components: selected to fall in the intended passband or stopband.
- Noise type and amplitude: documented for repeatable tests.
- Numeric representation: signed or unsigned, with agreed bit width and scaling.

---

## 9. Hardware and Software Interface

### UART Interface

UART carries data between MATLAB and the Zynq processor.

| Parameter | Planned/existing setting |
|---|---|
| COM port | COM3, subject to verification |
| Baud rate | 115200 |
| Data bits | 8 |
| Parity | None |
| Stop bits | 1 |
| Flow control | None |

The protocol must define how the filter mode is transmitted, how samples are framed, and how the PS indicates the output has been returned. Do not assume a filter-mode byte is included until it has been implemented on both sides.

### AXI GPIO Interface

The existing moving-average setup used two 17-bit GPIO channels:

| Channel | Direction | Existing signal allocation |
|---|---|---|
| Channel 1 | PS to PL | Bits `[15:0]`: sample; bit `[16]`: sample-valid |
| Channel 2 | PL to PS | Bits `[15:0]`: result; bit `[16]`: output-valid |

The new design may need extra control bits or a separate register for `filter_en`. Update the Vivado design, wrapper RTL, and Vitis application together. Confirm the generated GPIO widths and addresses in the actual hardware platform and `xparameters.h`.

---

## 10. UART Protocol

The existing moving-average workflow represented each sample as two bytes, low byte first. If this format is retained, the sender and receiver must use the same sample encoding.

For an unsigned 16-bit sample `S`:

```text
S = LowByte + (256 × HighByte)
```

For signed samples, use a defined two's-complement encoding and reconstruct the signed value correctly on both sides.

A robust protocol for the selectable filter system should specify:

1. How the filter mode is sent.
2. Whether the mode is sent once per block or with every sample.
3. How input samples are framed.
4. How the receiver identifies the beginning and end of a block.
5. How the output-valid handshake is managed.
6. How errors, timeouts, and incomplete transfers are handled.

The protocol is a design requirement and should be documented after both MATLAB and embedded C implement the same format.

---

## 11. Recommended Project Structure

```text
FPGA-Selectable-FIR-Filters/
|
+-- README.md
|
+-- rtl/
|   +-- fir_lpf.v
|   +-- fir_hpf.v
|   +-- fir_bpf.v
|   +-- fir_bsf.v
|   +-- combine_filter.v
|   +-- dsp_gpio_wrapper.v
|   +-- testbench/
|       +-- tb_combine_filter.v
|
+-- matlab/
|   +-- generate_input.m
|   +-- design_coefficients.m
|   +-- selectable_fir_test.m
|   +-- compare_results.m
|
+-- vitis/
|   +-- src/
|       +-- main.c
|
+-- vivado/
|   +-- constraints/
|   |   +-- design.xdc
|   +-- scripts/
|       +-- build.tcl
|
+-- results/
|   +-- figures/
|   |   +-- input_signal.png
|   |   +-- filter_responses.png
|   |   +-- output_comparison.png
|   |   +-- error_analysis.png
|   +-- data/
|       +-- filter_results.csv
|
+-- docs/
    +-- block_diagram.png
    +-- timing_summary.png
    +-- utilization_report.png
```

This is a recommended structure. Include only files that exist in the repository, and update the names to match the final design.

---

## 12. Implementation Procedure

### A. MATLAB Filter Design

1. Define the sampling frequency and required passband/stopband edges.
2. Design LPF, HPF, BPF, and BSF coefficient sets.
3. Plot each coefficient set's frequency response.
4. Quantize coefficients if fixed-point arithmetic is used in RTL.
5. Build a reference model that matches RTL precision, rounding, and startup behavior.
6. Generate test vectors for each filter mode.

### B. Vivado Hardware Design

1. Open the ZedBoard Vivado project.
2. Configure the Zynq-7000 Processing System and required UART.
3. Enable the processor AXI master interface.
4. Add and configure AXI GPIO and interconnect.
5. Add the FIR RTL modules and output-selection logic.
6. Connect sample, mode, valid, clock, and reset signals.
7. Confirm signal widths and address assignments.
8. Validate the block design.
9. Run synthesis and implementation.
10. Review timing and utilization reports.
11. Generate the bitstream and export the hardware platform.

### C. Vitis Embedded Software

1. Build an application for the exported hardware platform.
2. Configure the UART and AXI GPIO drivers using generated platform definitions.
3. Receive the mode and input samples according to the agreed protocol.
4. Write samples and control information to the PL.
5. Wait for the output-valid indication.
6. Read the filtered output.
7. Transmit the result to MATLAB in the agreed format.

### D. MATLAB Hardware Test

1. Connect and program the ZedBoard.
2. Start the embedded application.
3. Select a filter mode in MATLAB.
4. Send the test samples.
5. Receive all output samples.
6. Compare them with the matching reference model.
7. Plot the input and filtered outputs.
8. Save numerical results and implementation reports.

---

## 13. Verification and Result Analysis

### Functional Verification

Test each mode independently using signals with components in both passbands and stopbands.

| Test | Expected behavior |
|---|---|
| LPF with a low-frequency component | Component should pass with designed passband gain |
| LPF with a high-frequency component | Component should be attenuated |
| HPF with a low-frequency component | Component should be attenuated |
| HPF with a high-frequency component | Component should pass |
| BPF with a component inside the selected band | Component should pass |
| BPF with a component outside the band | Component should be attenuated |
| BSF with a component inside the stopband | Component should be attenuated |
| BSF with components outside the stopband | Components should pass |
| Reset/startup test | Output should follow the documented initial-state behavior |
| Mode-change test | Output should correspond to the selected mode according to the documented transition policy |

### MATLAB Comparison

For every mode, compare the FPGA result with a matching MATLAB reference. If the RTL uses quantized coefficients and fixed-point arithmetic, the reference should model those same choices to distinguish implementation errors from expected quantization differences.

Useful metrics include:

- Maximum absolute error.
- Mean squared error (MSE).
- Number of mismatched samples.
- Passband ripple.
- Stopband attenuation.
- Cutoff frequency and transition-band width.
- Latency and throughput.

### Hardware Results to Record

| Category | Parameters |
|---|---|
| FPGA utilization | LUTs, flip-flops, DSP slices, BRAM |
| Timing | Clock target, WNS, critical-path delay, maximum supported frequency |
| Performance | Latency, throughput, samples processed per second |
| Power | Tool-estimated or board-measured power, with method stated |
| Signal quality | Frequency response, passband ripple, stopband attenuation, numerical error |

### Results Status

No measured results for the four selectable FIR filters are claimed in this README. Fill in the tables and plots after the design is implemented and tested on the board. Clearly label simulation results, Vivado estimates, and physical measurements.

---

## 14. Troubleshooting

### MATLAB UART Timeout

- Verify the COM port in Device Manager.
- Ensure the Vitis application is running.
- Program the bitstream matching the current hardware design.
- Check baud rate and sample encoding.
- Close other programs that may be using the UART.
- Verify the mode/sample framing and valid handshake.

### Output Does Not Match MATLAB

- Verify the selected mode on both MATLAB and RTL.
- Confirm that the correct coefficient set is selected.
- Check coefficient quantization and scaling.
- Check signed versus unsigned sample interpretation.
- Confirm accumulator width and overflow behavior.
- Check startup state and sample ordering.
- Verify that MATLAB and RTL use the same rounding convention.

### Filter Does Not Show Expected Noise Reduction

- Confirm the noise frequencies relative to the filter passband and stopband.
- Check the sampling frequency and Nyquist limit.
- Inspect the designed coefficient frequency response.
- Ensure the correct coefficient set is selected.
- Verify that the implemented RTL is a true FIR datapath, not a sample-value threshold circuit.

### Timing Constraints Are Not Met

- Inspect the critical timing path.
- Review multiplier, adder, and accumulator structures.
- Consider pipelining or a different FIR architecture.
- Re-run implementation and document the resulting timing reports.
- Do not claim the target clock is met unless the timing report supports it.

---

## 15. Applications

- Sensor-signal conditioning.
- Audio and communications signal processing.
- Removing unwanted frequency components from sampled data.
- FPGA-based DSP education and demonstrations.
- Embedded real-time signal processing.
- Hardware/software co-design experiments.

---

## 16. Future Improvements

- Complete and verify all four FIR RTL implementations.
- Add a documented filter-selection protocol from MATLAB.
- Compare parallel and shared-datapath architectures.
- Optimize coefficient and arithmetic bit widths.
- Add automated RTL regression tests.
- Measure resource utilization, timing, and power.
- Compare FPGA output with a fixed-point MATLAB reference.
- Add live plots and automated result export.
- Explore adaptive filtering or FFT-based analysis.

---

## 17. Author

**Name:** Naveenraj S  
**Department:** Electronics and Communication Engineering  
**Institution:** Bannari Amman Institute of Technology  
**LinkedIn:** [Naveenraj S](https://www.linkedin.com/in/naveenraj07/)

---

## Project Summary

This project is intended to demonstrate four selectable FIR filter responses on a Zynq-7000 FPGA, with MATLAB generating input signals and analyzing output data. The planned workflow integrates MATLAB, UART, embedded C, AXI GPIO, and Verilog RTL. The completed design should be validated against reference outputs and documented with measured hardware utilization, timing, and signal-processing results.
