"""Standalone manual generation contracts: python tests/test_manual_generator.py."""
import copy
import importlib.util
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("manual_generator", ROOT / "tools/sync_timeline_manual.py")
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)

class ManualGeneration(unittest.TestCase):
    def setUp(self):
        self.text = generator.MANUAL.read_text(encoding="utf-8")
        self.catalog, self.stages = generator.sources()

    def test_checked_in_manual_is_current_and_generation_is_idempotent(self):
        result = generator.render(self.text, self.catalog, self.stages)
        self.assertEqual(self.text, result)
        self.assertEqual(result, generator.render(result, self.catalog, self.stages))

    def test_catalog_changes_update_both_visible_and_embedded_content(self):
        self.catalog["95"]["display_name"] = "TEST CORE"
        self.catalog["95"]["hp"] = 4321
        result = generator.render(self.text, self.catalog, self.stages)
        self.assertNotEqual(self.text, result)
        self.assertIn('<td>4321</td><td>TEST CORE</td>', result)
        block = re.search(r'<script id="manual-data" type="application/json">(.*?)</script>', result)
        self.assertEqual(json.loads(block[1])["catalog"], self.catalog)

    def test_arbitrary_author_notes_cannot_close_embedded_script(self):
        comment = '</script><img src=x onerror="bad">'
        self.stages["5"]["events"].append({"comment": comment})
        result = generator.render(self.text, self.catalog, self.stages)
        block = re.search(r'<script id="manual-data" type="application/json">(.*?)</script>', result)
        self.assertEqual(json.loads(block[1])["stages"]["5"]["events"][-1]["comment"], comment)
        self.assertNotIn(comment, result)

    def test_backup_files_are_excluded_and_new_stage_is_included(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            data = root / "data"
            data.mkdir()
            (data / "enemies.json").write_text(json.dumps({"entities": self.catalog}), encoding="utf-8")
            document = copy.deepcopy(self.stages["5"])
            (data / "stage06.json").write_text(json.dumps(document), encoding="utf-8")
            (data / "stage06_bak.json").write_text("invalid backup is not game data", encoding="utf-8")
            catalog, stages = generator.sources(root)
            self.assertEqual(list(stages), ["6"])
            result = generator.render(self.text, catalog, stages)
            self.assertIn('<option value="6">일반 6면</option>', result)
            self.assertIn('../data/stage06.json', result)
            self.assertNotIn('stage06_bak', result)

if __name__ == "__main__":
    unittest.main()
