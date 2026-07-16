from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


MODULE_PATTERN = re.compile(r"\bmodule\s+([A-Za-z_][A-Za-z0-9_$]*)\b")
INSTANTIATION_PATTERN = re.compile(
    r"(?m)^\s*(?!module\b)([A-Za-z_][A-Za-z0-9_$]*)\s*(?:#\s*\([^;]*?\))?\s+"
    r"[A-Za-z_][A-Za-z0-9_$]*\s*\("
)
VERILOG_KEYWORDS = {
    "always",
    "always_comb",
    "always_ff",
    "always_latch",
    "assign",
    "automatic",
    "begin",
    "buf",
    "case",
    "casex",
    "casez",
    "cmos",
    "deassign",
    "disable",
    "else",
    "end",
    "endcase",
    "for",
    "force",
    "function",
    "generate",
    "if",
    "initial",
    "nand",
    "nor",
    "not",
    "or",
    "output",
    "primitive",
    "pullup",
    "release",
    "repeat",
    "rnmos",
    "rtran",
    "rtranif0",
    "rtranif1",
    "task",
    "tran",
    "tranif0",
    "tranif1",
    "while",
    "xnor",
    "xor",
}


class ModuleInventoryError(ValueError):
    pass


@dataclass(frozen=True)
class ModuleInventory:
    defined_modules: set[str]
    referenced_modules: set[str]
    missing_modules: set[str]


def remove_comments(source: str) -> str:
    without_block_comments = re.sub(r"/\*.*?\*/", "", source, flags=re.DOTALL)
    return re.sub(r"//.*$", "", without_block_comments, flags=re.MULTILINE)


def read_verilog_sources(root: Path) -> list[str]:
    return [
        path.read_text(encoding="utf-8", errors="replace")
        for path in sorted(root.rglob("*"))
        if path.is_file() and path.suffix.lower() in {".v", ".vh"}
    ]


def validate_variant(root: Path) -> ModuleInventory:
    if not root.is_dir():
        raise ModuleInventoryError(f"RTL variant directory does not exist: {root}")

    sources = [remove_comments(source) for source in read_verilog_sources(root)]
    if not sources:
        raise ModuleInventoryError(f"RTL variant contains no Verilog sources: {root}")

    defined_modules = {
        module_name
        for source in sources
        for module_name in MODULE_PATTERN.findall(source)
    }
    referenced_modules = {
        module_name
        for source in sources
        for module_name in INSTANTIATION_PATTERN.findall(source)
        if module_name not in VERILOG_KEYWORDS
    }
    missing_modules = referenced_modules - defined_modules
    inventory = ModuleInventory(defined_modules, referenced_modules, missing_modules)
    if missing_modules:
        missing_list = ", ".join(sorted(missing_modules))
        raise ModuleInventoryError(f"Missing module definitions in {root}: {missing_list}")
    return inventory


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate a Verilog module dependency graph.")
    parser.add_argument("variant", type=Path, help="Directory containing .v and .vh sources")
    arguments = parser.parse_args()
    inventory = validate_variant(arguments.variant)
    print(
        f"defined={len(inventory.defined_modules)} "
        f"referenced={len(inventory.referenced_modules)} missing=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
