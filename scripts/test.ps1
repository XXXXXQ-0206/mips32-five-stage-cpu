$ErrorActionPreference = 'Stop'

python -m unittest discover -s tests -v

if (Get-Command iverilog -ErrorAction SilentlyContinue) {
    bash scripts/test-hdl.sh
} else {
    Write-Warning 'Icarus Verilog is unavailable; GitHub Actions compiles the HDL.'
}
