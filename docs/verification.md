# Verification

`tools/rtl_inventory.py` scans `.v` and `.vh` files and fails on unresolved module references. Its behavior is covered by the tests in `tests/`.

`scripts/test-hdl.sh` compiles every variant with Icarus Verilog and runs Verilator lint. GitHub Actions provides the authoritative portable HDL compilation gate. Board-specific timing closure and FPGA behavior are outside repository CI.
