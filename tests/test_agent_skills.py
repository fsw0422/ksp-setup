import json
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "setup-agent-skills.sh"


class AgentSkillSetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="ksp-skills-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.marketplace = self.root / "marketplace with spaces"
        self.destination = self.root / "codex skills"
        (self.marketplace / ".claude-plugin").mkdir(parents=True)
        self.manifest = self.marketplace / ".claude-plugin/plugin.json"

    def write_manifest(self, paths):
        self.manifest.write_text(json.dumps({"skills": paths}))

    def add_skill(self, name, content="original"):
        folder = self.marketplace / name
        folder.mkdir(exist_ok=True)
        (folder / "SKILL.md").write_text(content)

    def run_function(self, code, *arguments):
        return subprocess.run(
            ["bash", "-c", 'source "$1"; shift; ' + code, "test", str(SCRIPT),
             *map(str, arguments)],
            text=True, capture_output=True,
        )

    def link(self):
        return self.run_function('link_codex_skills "$1" "$2"',
                                 self.marketplace, self.destination)

    def test_links_only_manifest_skills_and_is_repeatable(self):
        self.write_manifest(["./one", "./two"])
        for name in ("one", "two", "unlisted"):
            self.add_skill(name)
        for _ in range(2):
            result = self.link()
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual({p.name for p in self.destination.iterdir()}, {"one", "two"})
        for name in ("one", "two"):
            self.assertTrue((self.destination / name).is_symlink())
            self.assertEqual((self.destination / name).resolve(), (self.marketplace / name).resolve())

    def test_updated_source_and_new_manifest_entry(self):
        self.add_skill("one")
        self.write_manifest(["./one"])
        self.assertEqual(self.link().returncode, 0)
        self.add_skill("one", "updated")
        self.assertEqual((self.destination / "one/SKILL.md").read_text(), "updated")
        self.add_skill("two")
        self.write_manifest(["./one", "./two"])
        self.assertEqual(self.link().returncode, 0)
        self.assertTrue((self.destination / "two").is_symlink())

    def test_missing_source_fails_before_creating_any_link(self):
        self.add_skill("one")
        self.write_manifest(["./one", "./missing"])
        result = self.link()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.destination.exists())

    def test_unrelated_entries_are_preserved_before_any_links_are_created(self):
        self.add_skill("one")
        self.add_skill("two")
        self.write_manifest(["./one", "./two"])
        for kind in ("file", "directory", "symlink", "dangling-symlink"):
            with self.subTest(kind=kind):
                self.destination = self.root / kind
                self.destination.mkdir()
                conflict = self.destination / "two"
                if kind == "file":
                    conflict.write_text("keep me")
                elif kind == "directory":
                    conflict.mkdir()
                else:
                    target = self.root / ("missing" if kind == "dangling-symlink" else "real")
                    if kind == "symlink":
                        target.mkdir()
                    conflict.symlink_to(target)
                result = self.link()
                self.assertNotEqual(result.returncode, 0)
                self.assertTrue(conflict.exists() or conflict.is_symlink())
                self.assertFalse((self.destination / "one").is_symlink())
                if kind == "file":
                    self.assertEqual(conflict.read_text(), "keep me")

    def test_invalid_manifest_paths_are_rejected(self):
        for paths in ([], "./one", ["../outside"], ["./../outside"],
                      ["/absolute"], ["./one\n./two"], [1]):
            with self.subTest(paths=paths):
                self.write_manifest(paths)
                self.assertNotEqual(self.link().returncode, 0)
                self.assertFalse(self.destination.exists())

    def test_missing_marketplace_has_no_side_effects(self):
        result = self.link()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("checkout is missing", result.stderr)
        self.assertFalse(self.destination.exists())

    def test_install_refreshes_both_plugins(self):
        result = self.run_function('claude() { printf "%s\\n" "$*"; }; install_claude_plugins')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), [
            "plugin install skills --marketplace fsw0422/skills --scope user",
            "plugin update skills@fsw0422 --scope user",
            "plugin install playwright-chromium-browser@fsw0422 --scope user",
            "plugin update playwright-chromium-browser@fsw0422 --scope user",
        ])

    def test_failed_install_stops_before_linking(self):
        result = self.run_function('install_claude_plugins() { return 1; }; '
                                   'link_codex_skills() { echo UNEXPECTED_LINK; }; main both')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("UNEXPECTED_LINK", result.stdout)

    def test_modes_and_custom_claude_plugin_directory(self):
        for mode, expected in (("both", ["INSTALL", "LINK"]),
                               ("claude", ["INSTALL"]),
                               ("codex", ["LINK"]), ("link-only", ["LINK"])):
            with self.subTest(mode=mode):
                result = self.run_function(
                    'install_claude_plugins() { echo INSTALL; }; '
                    'link_codex_skills() { '
                    'test "$1" = "$CLAUDE_CODE_PLUGIN_CACHE_DIR/marketplaces/fsw0422" || return 1; '
                    'test "$2" = "$HOME/.agents/skills" || return 1; echo LINK; }; '
                    'CLAUDE_CODE_PLUGIN_CACHE_DIR="$2" main "$1"', mode, self.root / "plugins")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.splitlines(), expected)


if __name__ == "__main__":
    unittest.main()
