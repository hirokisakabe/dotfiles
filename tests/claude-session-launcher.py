"""Run with python3 tests/claude-session-launcher.py; never launches real Claude."""

import json
import os
from pathlib import Path
import re
import sqlite3
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "packages/claude/.claude/scripts/session-launcher.py"
SESSION = "11111111-1111-1111-1111-111111111111"
OLD_SESSION = "22222222-2222-2222-2222-222222222222"


class LauncherTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.config = self.root / "config"
        self.config.mkdir()
        self.main = self.root / "main repo"
        self.worktree = self.root / "worktree 日本語"
        self.main.mkdir()
        self.worktree.mkdir()
        binaries = self.root / "bin"
        binaries.mkdir()
        programs = {
            "fzf": 'import os,sys\nrows=sys.stdin.read().splitlines()\nif os.environ.get("CANCEL"): sys.exit(130)\nprint(next(row for row in rows if row.startswith(os.environ["SELECT"])))\n',
            "claude": 'import json,os,sys\nopen(os.environ["CAPTURE"],"w").write(json.dumps({"cwd":os.getcwd(),"args":sys.argv[1:]}))\n',
        }
        for name, body in programs.items():
            path = binaries / name
            path.write_text(f"#!{sys.executable}\n{body}")
            path.chmod(0o755)
        self.env = dict(os.environ, CLAUDE_CONFIG_DIR=str(self.config),
                        PATH=str(binaries) + os.pathsep + os.environ["PATH"],
                        CAPTURE=str(self.root / "capture.json"), SELECT=SESSION)

    def run_launcher(self, *args, **overrides):
        return subprocess.run([sys.executable, str(SCRIPT), *args],
                              env=dict(self.env, **overrides), text=True, capture_output=True)

    def record(self, **event):
        event.setdefault("session_id", SESSION)
        event.setdefault("cwd", str(self.main))
        result = subprocess.run([sys.executable, str(SCRIPT), "record"],
                                input=json.dumps(event), env=self.env,
                                text=True, capture_output=True)
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))

    def assert_resumed(self, session=SESSION):
        result = self.run_launcher(SELECT=session)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads((self.root / "capture.json").read_text()),
                         {"cwd": str(self.worktree), "args": ["--resume", session]})

    def test_resume_after_entering_worktree(self):
        self.record(hook_event_name="SessionStart")
        self.record(hook_event_name="UserPromptSubmit", prompt="作業を再開\n確認")
        self.record(hook_event_name="CwdChanged", new_cwd=str(self.worktree))
        self.assert_resumed()
        with sqlite3.connect(self.config / "task-launcher/sessions.sqlite3") as db:
            self.assertEqual(db.execute("SELECT title FROM sessions").fetchone()[0], "作業を再開 確認")

    def test_import_history_and_resolve_worktree(self):
        (self.config / "history.jsonl").write_text("bad JSON\n" + json.dumps({
            "sessionId": OLD_SESSION, "project": str(self.main),
            "timestamp": 1000, "display": "old task"}) + "\n")
        project = self.config / "projects" / re.sub("[^a-zA-Z0-9]", "-", str(self.main))
        project.mkdir(parents=True)
        (project / (OLD_SESSION + ".jsonl")).write_text(json.dumps({
            "sessionId": OLD_SESSION, "cwd": str(self.worktree)}) + "\n")
        self.assert_resumed(OLD_SESSION)

    def test_cancel_and_missing_worktree_do_not_launch_claude(self):
        self.record(cwd=str(self.root / "missing"))
        self.assertEqual(self.run_launcher(CANCEL="1").returncode, 0)
        result = self.run_launcher()
        self.assertEqual(result.returncode, 1)
        self.assertIn("ディレクトリがありません", result.stderr)
        self.assertFalse((self.root / "capture.json").exists())

    def test_renamed_title_and_hook_priority_over_old_history(self):
        self.record(cwd=str(self.worktree), prompt="first", session_title="named task")
        (self.config / "history.jsonl").write_text(json.dumps({
            "sessionId": SESSION, "project": str(self.main),
            "timestamp": 9999999999999, "display": "old title"}) + "\n")
        self.assert_resumed()
        with sqlite3.connect(self.config / "task-launcher/sessions.sqlite3") as db:
            self.assertEqual(db.execute("SELECT title FROM sessions").fetchone()[0], "named task")

    def test_empty_history_and_invalid_hook_input(self):
        self.assertEqual(self.run_launcher().returncode, 0)
        result = subprocess.run([sys.executable, str(SCRIPT), "record"], input="bad JSON",
                                env=self.env, text=True, capture_output=True)
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))


if __name__ == "__main__":
    unittest.main()
