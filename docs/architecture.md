# Architecture

Each variant implements fetch, decode/register read, execute, memory access, and write-back stages. `Datapath.v`, `Controller.v`, `HazardUnit.v`, and `MIPS.v` form the control core. Arithmetic, branch, HI/LO, CP0, translation, bridge, cache, and AXI modules are separated by responsibility.

The SRAM variant exposes SRAM-like instruction and data interfaces. The AXI variants add bridge and interface logic; the prefetch/cache variant retains the most complete recovered cache path.
