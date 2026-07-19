# 🚀 Hardware-Accelerated LU Decomposition Engine

A parameterizable, in-place linear equation solver ($Ax = b$) architected in Verilog for Xilinx FPGA and Zynq SoC architectures. This hardware engine replaces sequential CPU software algorithms—which scale at $O(N^3)$ complexity and suffer from memory bottlenecks—with a deterministic, 3-loop RTL pipeline utilizing custom Q16.16 fixed-point arithmetic and dedicated DSP48E2 silicon acceleration.

Designed for ultra-low-latency mathematical calculation in real-time cyber-physical systems, including electrical grid load-flow analytics (Newton-Raphson iterations), robotics inverse kinematics, and adaptive radar beamforming.

---

## ✨ Key Architectural Features

* **In-Place Doolittle Algorithm:** Overwrites the input matrix $A$ directly in memory with the factored lower ($L$) and upper ($U$) triangular matrices as calculations complete, reducing hardware memory requirements by over 50%.
* **Zero-Latency Combinational Memory Reads:** Maps internal matrix storage to Xilinx Distributed RAM (LUTRAM) instead of synchronous Block RAM. This eliminates 1-cycle read latency, allowing the FSM to sample initial calculation operands instantly without stalling the pipeline.
* **DSP48E2 Arithmetic Mapping:** Infers physical FPGA DSP slices automatically for all signed 32-bit Q16.16 multiply-accumulate (MAC) operations, ensuring single-cycle execution for running dot-products.
* **Multi-Cycle Non-Restoring Divider:** Implements an iterative fixed-point division architecture for diagonal scaling ($L_{i,k} = \frac{x}{U_{k,k}}$), stalling the computation pipeline only during division phases while maintaining high clock frequencies.
* **3-Loop Finite State Machine:** A robust digital controller managing nested loop indexing ($k \to i \to j$), address generation, and handshaking across IDLE, READ_U, COMP_U, READ_L, COMP_L, and FINISH states.

---

## 📊 Physical Synthesis & Performance Results

Implemented and verified using **Xilinx Vivado** targeting a 7-Series / Zynq FPGA architecture with a **100 MHz** clock constraint:

### ⚡ Timing & Latency
| Metric | Result | Notes |
| :--- | :--- | :--- |
| **Max Operating Frequency ($F_{max}$)** | **326.8 MHz** | Achieved via +6.940 ns Worst Negative Slack (WNS) |
| **Execution Latency (Clock Cycles)** | **55 Cycles** | Deterministic completion time from `start` to `done` |
| **Real-Time Execution Speed** | **168 ns** | Total time to factor a 4x4 matrix at $F_{max}$ |
| **Timing Closure** | **0 Failing Endpoints** | Met all Setup, Hold, and Pulse Width silicon constraints |

### 🛠️ Hardware Resource Utilization
| FPGA Primitive | Consumed | Target Available | Utilization % | Architectural Mapping Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Slice LUTs** | 10,093 | 41,000 | **24.62%** | FSM routing multiplexers and iterative divider trees |
| **Slice Registers** | 597 | 82,000 | **0.73%** | Extremely low footprint achieved via in-place computation |
| **DSP Slices (DSP48E2)** | 8 | 240 | **3.33%** | Single-cycle 32-bit Q16.16 signed multiplication |
| **Distributed Memory** | 851 LUTs | — | — | Mapped to fast LUTRAM to enable 0-cycle combinational reads |
| **Clock Buffers (BUFG)** | 1 | 32 | **3.13%** | Single global clock network for synchronous FSM driving |

---

## 📂 Repository Structure

```text
├── src/
│   ├── lu_engine_top.v          # Top-level RTL core (FSM, Q16.16 math, Distributed RAM)
│   └── tb_lu_engine.v           # Self-checking Verilog verification testbench
├── sim/
│   └── generate_lu_golden.py    # Python test-vector generator & cycle-accurate golden model
├── docs/
│   ├── simulation_waveform.png  # Waveform proving 0-error behavioral verification
│   ├── utilization_report.png   # Vivado physical resource allocation table
│   └── timing_summary.png       # Vivado timing closure and WNS proof
└── README.md
