# MIPS32 Five-Stage CPU

[English](README.md) | [中文](README.zh-CN.md)

A coursework-derived MIPS32 five-stage pipelined CPU, preserved as three Verilog RTL variants: an SRAM-like baseline, an AXI functional implementation, and an AXI prefetch/cache implementation.

## Project Overview

The design follows fetch, decode, execute, memory, and write-back stages. The AXI variants add address translation, bus bridges, CP0 exception support, and instruction/data cache logic. This repository packages RTL with portable source-inventory checks and HDL compilation scripts; it does not distribute a prebuilt FPGA image.

## Features

- MIPS32 pipeline with forwarding and hazard handling.
- ALU, branch comparison, HI/LO, multiply/divide, and CLZ.
- CP0 exception and interrupt handling in AXI variants.
- SRAM-like, AXI functional, and AXI prefetch/cache variants.
- Automated module-graph validation and CI HDL compilation.

## Screenshots

This is RTL and command-line tooling, not a graphical application. No screenshots are included; see [Architecture](docs/architecture.md) and [Verification](docs/verification.md).

## Installation

```bash
git clone https://github.com/XXXXXQ-0206/mips32-five-stage-cpu.git
cd mips32-five-stage-cpu
```

Python 3.10+ runs source checks. Icarus Verilog and Verilator compile the HDL; CI installs both on Ubuntu.

## Usage

```bash
python tools/rtl_inventory.py rtl/axi-prefetch
python -m unittest discover -s tests -v
bash scripts/test-hdl.sh
```

On Windows, run `scripts/test.ps1`. It performs HDL compilation only when Icarus Verilog is on `PATH`.

## Build Instructions

`mycpu_top` is the synthesis top module. Board synthesis additionally needs compatible clocks, constraints, memory integration, and licensed toolchain collateral. Generated Vivado output, bitstreams, and board files are deliberately excluded.

```bash
iverilog -g2012 -s mycpu_top -tnull rtl/axi-prefetch/*.v
verilator --lint-only --Wno-fatal --top-module mycpu_top rtl/axi-prefetch/*.v
```

## Project Structure

```text
rtl/sram/             SRAM-like baseline
rtl/axi-functional/   AXI functional variant
rtl/axi-prefetch/     AXI prefetch/cache variant
tests/                Python source-validation tests
tools/                RTL inventory utility
scripts/              Local validation entry points
docs/                 Architecture, variants, and provenance
```

## Roadmap

- Add cycle-accurate self-checking architectural tests.
- Add an open FPGA reference integration when redistributable board collateral is available.
- Document performance measurements with reproducible constraints and tool versions.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md), follow the [Code of Conduct](CODE_OF_CONDUCT.md), and open changes against `dev`.

## License

User-authored files are available under the [MIT License](LICENSE). Read the [course-framework notice](docs/course-framework-notice.md) before adding course-provided or vendor files.

## FAQ

**Is this an official Loongson Cup entry?** No. It is a course project that follows compatible MIPS32-oriented laboratory specifications; it is not a competition submission.

**Can I synthesize it immediately?** Portable RTL compiles in CI. FPGA synthesis requires a compatible licensed toolchain and target-specific integration collateral.

**Why are generated Vivado files absent?** They are machine- and tool-version-specific outputs, not authoritative design source.

## Acknowledgements

The project was developed in an academic hardware-design setting. MIPS, Xilinx, Vivado, AXI, and related marks belong to their respective owners; mention does not imply endorsement.

## Disclaimer

This software is provided **AS IS**, without warranty of any kind. The author is not liable for any direct, indirect, incidental, special, or consequential damages arising from its use. You assume all risks when using, modifying, synthesizing, or deploying this software. Do not use it for unlawful, safety-critical, life-critical, production-network, or other applications where failure could cause harm unless you independently validate and accept full responsibility.
