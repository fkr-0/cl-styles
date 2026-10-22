"""Black-box negative coverage gate regressions; python3 -m unittest discover -s tests -p 'test_coverage_gate.py'."""
import importlib.util
import pathlib
import tempfile
import unittest

GATE = pathlib.Path(__file__).resolve().parents[1] / "scripts/coverage_gate.py"
spec = importlib.util.spec_from_file_location("styles_coverage_gate", GATE)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)

class GateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        (self.root / "src").mkdir()
        (self.root / "src/one.lisp").write_text("(defun one () 1)\n")
        (self.root / "src/two.lisp").write_text("(defun two () 2)\n")
        self.report = self.root / "coverage.info"
        self.report.write_text("SF:src/one.lisp\nDA:1,1\nend_of_record\n"
                               "SF:src/two.lisp\nDA:1,0\nend_of_record\n")

    def test_owned_zero_hit_file_is_present_in_denominator(self):
        data = gate.measure(self.root, self.report)
        self.assertEqual((data["covered"], data["lines"]), (1, 2))
        self.assertEqual(len(data["sources"]), 2)

    def test_missing_report_fails(self):
        self.report.unlink()
        with self.assertRaisesRegex(ValueError, "missing"):
            gate.measure(self.root, self.report)

    def test_missing_owned_file_fails(self):
        self.report.write_text("SF:src/one.lisp\nDA:1,1\nend_of_record\n")
        with self.assertRaisesRegex(ValueError, "missing/zero-instrumented"):
            gate.measure(self.root, self.report)

    def test_malformed_hit_record_fails(self):
        self.report.write_text("SF:src/one.lisp\nDA:not-a-line,3\nend_of_record\n")
        with self.assertRaises(ValueError):
            gate.measure(self.root, self.report)

    def test_zero_coverage_fails(self):
        self.report.write_text("SF:src/one.lisp\nDA:1,0\nend_of_record\n"
                               "SF:src/two.lisp\nDA:1,0\nend_of_record\n")
        with self.assertRaisesRegex(ValueError, "zero covered"):
            gate.measure(self.root, self.report)

    def test_stale_report_fails(self):
        import os
        import time
        future = time.time_ns() + 3_000_000_000
        os.utime(self.root / "src/one.lisp", ns=(future, future))
        with self.assertRaisesRegex(ValueError, "stale"):
            gate.measure(self.root, self.report)

if __name__ == "__main__":
    unittest.main()
