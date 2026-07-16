from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
CHECKER_PATH = REPOSITORY_ROOT / "tools" / "rtl_inventory.py"


def load_checker():
    if not CHECKER_PATH.exists():
        return None
    specification = importlib.util.spec_from_file_location("rtl_inventory", CHECKER_PATH)
    module = importlib.util.module_from_spec(specification)
    assert specification.loader is not None
    sys.modules[specification.name] = module
    specification.loader.exec_module(module)
    return module


class RtlInventoryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.checker = load_checker()

    def test_checker_is_present(self) -> None:
        self.assertIsNotNone(self.checker, "rtl inventory checker is missing")

    def test_detects_missing_module_reference(self) -> None:
        if self.checker is None:
            self.skipTest("checker implementation is not present")
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            (root / "top.v").write_text(
                "module top;\nmissing_unit unit();\nendmodule\n"
            )
            with self.assertRaises(self.checker.ModuleInventoryError):
                self.checker.validate_variant(root)

    def test_accepts_complete_module_graph(self) -> None:
        if self.checker is None:
            self.skipTest("checker implementation is not present")
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            (root / "top.v").write_text(
                "module top;\nchild_unit unit();\nendmodule\n"
            )
            (root / "child.v").write_text("module child_unit; endmodule\n")
            inventory = self.checker.validate_variant(root)
            self.assertEqual(inventory.missing_modules, set())
            self.assertEqual(inventory.defined_modules, {"top", "child_unit"})

    def test_ignores_verilog_control_flow_keywords(self) -> None:
        if self.checker is None:
            self.skipTest("checker implementation is not present")
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            (root / "top.v").write_text(
                "module top;\n"
                "always @(*) begin\n"
                "if (flag) begin\n"
                "end else begin\n"
                "end\n"
                "case (selector)\n"
                "0: begin end\n"
                "endcase\n"
                "end\n"
                "endmodule\n"
            )
            inventory = self.checker.validate_variant(root)
            self.assertEqual(inventory.referenced_modules, set())

    def test_recovered_variants_have_complete_module_graphs(self) -> None:
        if self.checker is None:
            self.skipTest("checker implementation is not present")
        for variant in ("sram", "axi-functional", "axi-prefetch"):
            inventory = self.checker.validate_variant(REPOSITORY_ROOT / "rtl" / variant)
            self.assertEqual(inventory.missing_modules, set(), variant)


if __name__ == "__main__":
    unittest.main()
