#!/usr/bin/env python3
"""Remember Claude tasks and resume one from any terminal with fzf."""

import datetime
import json
import os
from pathlib import Path
import re
import sqlite3
import subprocess
import sys
import unicodedata


CONFIG = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))


def clean(value):
    return " ".join(
        "".join(c if not unicodedata.category(c).startswith("C") else " " for c in value).split()
    )[:120]


def connect():
    directory = CONFIG / "task-launcher"
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    db = sqlite3.connect(directory / "sessions.sqlite3", timeout=5)
    db.execute("CREATE TABLE IF NOT EXISTS sessions (id TEXT PRIMARY KEY, cwd TEXT, title TEXT, updated REAL, recorded INTEGER)")
    db.execute("CREATE TABLE IF NOT EXISTS metadata (key TEXT PRIMARY KEY)")
    return db


def record(db):
    event = json.load(sys.stdin)
    session_id = event.get("session_id", "")
    cwd = event.get("new_cwd") or event.get("cwd")
    if not valid_id(session_id) or not cwd:
        return
    if event.get("hook_event_name") == "SessionStart":
        import_history(db)
    previous = db.execute("SELECT title FROM sessions WHERE id = ?", (session_id,)).fetchone()
    title = event.get("session_title") or (previous[0] if previous else "")
    if not title and event.get("prompt"):
        title = clean(event["prompt"])
    db.execute(
        "INSERT OR REPLACE INTO sessions VALUES (?, ?, ?, ?, 1)",
        (session_id, cwd, clean(title), datetime.datetime.now().timestamp()),
    )
    db.commit()


def valid_id(value):
    return bool(re.fullmatch(r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}", value))


def import_history(db):
    # One-time compatibility import. history.jsonl is an internal format;
    # new sessions use the documented hook inputs instead.
    if db.execute("SELECT 1 FROM metadata WHERE key = 'history-imported'").fetchone():
        return
    history = CONFIG / "history.jsonl"
    if history.exists():
        with history.open() as source:
            for line in source:
                try:
                    entry = json.loads(line)
                    session_id = entry.get("sessionId", "")
                    cwd = entry.get("project")
                    if not valid_id(session_id) or not cwd:
                        continue
                    updated = float(entry.get("timestamp", 0)) / 1000
                    title = clean(entry.get("display", ""))
                    db.execute(
                        "INSERT INTO sessions VALUES (?, ?, ?, ?, 0) "
                        "ON CONFLICT(id) DO UPDATE SET "
                        "title = CASE WHEN sessions.title = '' THEN excluded.title ELSE sessions.title END, "
                        "cwd = CASE WHEN sessions.recorded = 0 AND excluded.updated > sessions.updated "
                        "THEN excluded.cwd ELSE sessions.cwd END, "
                        "updated = CASE WHEN sessions.recorded = 0 AND excluded.updated > sessions.updated "
                        "THEN excluded.updated ELSE sessions.updated END",
                        (session_id, cwd, title, updated),
                    )
                except (ValueError, TypeError, AttributeError):
                    continue
    db.execute("INSERT OR IGNORE INTO metadata VALUES ('history-imported')")
    db.commit()


def imported_cwd(session_id, cwd):
    # Older sessions may have entered a worktree after starting in main.
    # Read only the selected transcript, never tool output or subagent files.
    project = re.sub(r"[^a-zA-Z0-9]", "-", cwd)
    transcript = CONFIG / "projects" / project / (session_id + ".jsonl")
    if not transcript.exists():
        matches = list((CONFIG / "projects").glob(f"*/{session_id}.jsonl"))
        if len(matches) != 1:
            raise ValueError("会話の履歴ファイルを一意に特定できません: " + session_id)
        transcript = matches[0]
    relocated = None
    if transcript.exists():
        with transcript.open() as source:
            for line in source:
                try:
                    entry = json.loads(line)
                    if entry.get("sessionId") == session_id:
                        if entry.get("cwd"):
                            cwd = entry["cwd"]
                        if entry.get("type") == "relocated" and entry.get("relocatedCwd"):
                            relocated = entry["relocatedCwd"]
                except (ValueError, AttributeError):
                    continue
    return relocated or cwd


def launch(db):
    import_history(db)
    rows = db.execute("SELECT id, cwd, title, updated, recorded FROM sessions ORDER BY updated DESC").fetchall()
    if not rows:
        print("再開できる作業がありません。Claude で会話すると自動で記録されます。", file=sys.stderr)
        return 0
    choices = []
    for session_id, cwd, title, updated, _ in rows:
        date = datetime.datetime.fromtimestamp(updated).strftime("%m/%d %H:%M")
        display_cwd = cwd.replace(str(Path.home()) + "/", "~/", 1)
        missing = " [場所なし]" if not Path(cwd).is_dir() else ""
        choices.append(f"{session_id}\t{date}\t{clean(title) or '(タイトルなし)'}\t{clean(display_cwd)}{missing}")
    result = subprocess.run(
        ["fzf", "--delimiter=\t", "--with-nth=2..", "--no-multi", "--layout=reverse",
         "--prompt=作業を再開 > ", "--header=プロジェクト・作業内容で検索 / Enter: 再開 / Esc: 終了"],
        input="\n".join(choices), text=True, stdout=subprocess.PIPE,
    )
    if result.returncode in (1, 130):
        return 0
    if result.returncode:
        return result.returncode
    session_id = result.stdout.split("\t", 1)[0].strip()
    selected = next((row for row in rows if row[0] == session_id), None)
    if not selected:
        return 1
    _, cwd, _, _, recorded = selected
    if not recorded:
        cwd = imported_cwd(session_id, cwd)
    if not Path(cwd).is_dir():
        print(f"作業ディレクトリがありません: {cwd}\nworktree を復元してから再開してください。", file=sys.stderr)
        return 1
    db.close()
    os.chdir(cwd)
    os.execvp("claude", ["claude", "--resume", session_id])


def main():
    recording = sys.argv[1:] == ["record"]
    try:
        db = connect()
        if recording:
            record(db)
            return 0
        if sys.argv[1:]:
            print("Usage: session-launcher.py [record]", file=sys.stderr)
            return 2
        return launch(db)
    except KeyboardInterrupt:
        return 0
    except (OSError, ValueError, sqlite3.Error) as error:
        # A launcher failure must never interrupt a Claude conversation.
        if not recording:
            print(f"作業を再開できませんでした: {error}", file=sys.stderr)
            return 1
        return 0


if __name__ == "__main__":
    sys.exit(main())
