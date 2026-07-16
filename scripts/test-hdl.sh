#!/usr/bin/env bash
set -euo pipefail

for variant in sram axi-functional axi-prefetch; do
  mapfile -t sources < <(find "rtl/${variant}" -maxdepth 1 -type f -name '*.v' | sort)
  test "${#sources[@]}" -gt 0
  iverilog -g2012 -I "rtl/${variant}" -s mycpu_top -tnull "${sources[@]}"
  verilator --lint-only --Wno-fatal -I"rtl/${variant}" --top-module mycpu_top "${sources[@]}"
done
