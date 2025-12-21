# RISCV32IB - 32-Bit Pipelined RISC-V Processor

![Status](https://img.shields.io/badge/Status-Completed-success)
![Language](https://img.shields.io/badge/Language-SystemVerilog-blue)
![Platform](https://img.shields.io/badge/Tool-Verilator-orange)

> A 5-stage pipelined RISC-V processor implementation supporting RV32I Base Integer Instruction Set and M-Extension.

---

## 📑 Project Presentation
For a detailed explanation of the datapath, control logic, and performance analysis, please view the project presentation:

[![View Presentation PDF](https://img.shields.io/badge/View_Presentation-PDF-red?style=for-the-badge&logo=adobeacrobatreader)](docs/latexSunum/slides.pdf)

---

## 🚀 Key Features

* **ISA:** RISC-V RV32IM (Integer + Multiplication Extension).
* **Microarchitecture:** 5-Stage Pipeline (IF, ID, EX, MEM, WB).
* **Hazard Handling:**
    * **Data Hazards:** Resolved via Forwarding Unit and Stalling.
    * **Control Hazards:** Handled with stalling and flushing.
* **Verification:** Verified using Verilator and GTKWave with custom testbenches.

## 📂 Repository Structure

```text
.
├── docs/            # Presentation slides and documentation
│   └── latexSunum   
│       └── slides.pdf  
├── riscv-tests/     # Testcases, assembly files and simulation scripts
├── src/             # SystemVerilog source files (Datapath, Control Unit, etc.)
├── tb/              # Testbench codes
├── makefile         # Makefile for Verilator compilation
├── LICENSE          # License file
├── README.md        # This file
└── verify_tests.py  # Automation script to run all testcases and verify functionality

---

🛠️ Tools & Technologies

    Language: SystemVerilog / Verilog

    Compilation: RISC-V GNU Toolchain

    Simulation: Verilator & Spike (RISC-V ISA Simulator)

    Waveform Viewer: GTKWave

    Scripts: Python (for test generation and automation)

    Documentation: LaTeX (Beamer)

---

📊 Block Diagram

---

⚙️ How to Run & Simulation

To simulate the processor and run the testbenches, follow the steps below.
1. Prerequisites

Make sure you have the following tools installed:

    Verilator (v4.0 or later)

    Python 3 (with numpy)

    GTKWave (for waveform visualization)

    RISC-V Toolchain (gcc-riscv32-unknown-elf)

    Spike (RISC-V ISA Simulator)

2. Running the Simulation

    I have provided Python scripts to automate the testing process.
    A. Running All Verification Tests

    To run all test hex codes in the core and check whether they pass or fail:

    ⚠️ Attention: Before running this script, ensure your Fetch Stage uses the generic
    ```systemverilog
    instruction.hex
    ```
    file in the
    ```systemverilog
    $readmemh
    ```
    block:
    ```systemverilog
    initial $readmemh("instruction.hex", instruction_memory, 0, MEM_SIZE);
    ```
---

```bash
# Run the verification script from the root folder
python3 verify_tests.py
```
B. Generating Assembly Tests

If you want to generate hex files from assembly code:
```bash
# Navigate to riscv-tests folder
cd riscv-tests

# Run the build script to simulate assembly (.s) codes
python3 full_build.py
```
C. Manual Testing (Specific Testcase)

To run a specific test case manually:

 1. Modify the 
    ```systemverilog 
    initial
    ``` 
    block in your Fetch Stage module to point to the specific hex file:
    ```systemverilog
    initial $readmemh("./riscv-tests/{name}/verification_output/{name}_pure.hex", instruction_memory, 0, MEM_SIZE);
    ```
 2. Run the simulation using Make:
    ```bash 
    # Navigate to root folder
    make run > output.log
    ``` 
📚 References

    Harris, D. M., & Harris, S. L. (2021). Digital Design and Computer Architecture: RISC-V Edition. Morgan Kaufmann.

    Patterson, D. A., & Hennessy, J. L. (2020). Computer Organization and Design RISC-V Edition: The Hardware Software Interface. Morgan Kaufmann.

    Hennessy, J. L., & Patterson, D. A. (2017). Computer Architecture: A Quantitative Approach. Morgan Kaufmann.

    RISC-V Instruction Set Manual, Volume I: Unprivileged ISA.

Author: Fatih Sarıduman