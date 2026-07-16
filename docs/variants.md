# RTL Variants

| Directory | Interface | Intended use |
| --- | --- | --- |
| `rtl/sram` | SRAM-like instruction and data ports | Pipeline baseline |
| `rtl/axi-functional` | AXI | Functional AXI integration |
| `rtl/axi-prefetch` | AXI with cache/prefetch logic | Complete recovered integration |

All variants use `mycpu_top` as their top module.
