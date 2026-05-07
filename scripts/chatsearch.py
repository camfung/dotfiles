#!/usr/bin/env python3
"""Search ~/.claude/projects jsonl logs for a keyword and resume the picked chat.

Usage:
    chatsearch.py <query> [--regex] [--case-sensitive] [--limit N]
"""

from __future__ import annotations

import argparse
import curses
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

PROJECTS_DIR = Path.home() / ".claude" / "projects"
SNIPPET_RADIUS = 80


@dataclass
class Match:
    session_id: str
    cwd: str
    timestamp: str
    role: str
    file: Path
    snippet: str
    match_start: int  # offset into snippet where match begins
    match_end: int


def extract_text(content) -> str:
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for item in content:
            if not isinstance(item, dict):
                continue
            t = item.get("type")
            if t == "text":
                parts.append(item.get("text", ""))
            elif t == "tool_use":
                inp = item.get("input")
                if isinstance(inp, (dict, list)):
                    parts.append(json.dumps(inp))
                elif isinstance(inp, str):
                    parts.append(inp)
            elif t == "tool_result":
                tc = item.get("content")
                parts.append(extract_text(tc))
        return "\n".join(parts)
    if isinstance(content, dict):
        return extract_text(content.get("content"))
    return ""


def make_snippet(text: str, m: re.Match) -> tuple[str, int, int]:
    start = max(0, m.start() - SNIPPET_RADIUS)
    end = min(len(text), m.end() + SNIPPET_RADIUS)
    prefix = "…" if start > 0 else ""
    suffix = "…" if end < len(text) else ""
    snippet = prefix + text[start:end] + suffix
    snippet = snippet.replace("\n", " ").replace("\r", " ")
    new_start = len(prefix) + (m.start() - start)
    new_end = new_start + (m.end() - m.start())
    return snippet, new_start, new_end


def search_file(path: Path, pattern: re.Pattern) -> Iterable[Match]:
    try:
        with path.open("r", encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    rec = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if rec.get("type") not in ("user", "assistant"):
                    continue
                msg = rec.get("message")
                if not isinstance(msg, dict):
                    continue
                text = extract_text(msg.get("content"))
                if not text:
                    continue
                m = pattern.search(text)
                if not m:
                    continue
                snippet, s, e = make_snippet(text, m)
                yield Match(
                    session_id=rec.get("sessionId", ""),
                    cwd=rec.get("cwd", "") or "",
                    timestamp=rec.get("timestamp", "") or "",
                    role=rec.get("type", ""),
                    file=path,
                    snippet=snippet,
                    match_start=s,
                    match_end=e,
                )
    except OSError:
        return


def search_all(query: str, regex: bool, case_sensitive: bool) -> list[Match]:
    flags = 0 if case_sensitive else re.IGNORECASE
    pat_str = query if regex else re.escape(query)
    pattern = re.compile(pat_str, flags)
    results: list[Match] = []
    for jsonl in PROJECTS_DIR.rglob("*.jsonl"):
        results.extend(search_file(jsonl, pattern))
    results.sort(key=lambda m: m.timestamp, reverse=True)
    return results


def picker(stdscr, matches: list[Match]) -> Match | None:
    curses.curs_set(0)
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_CYAN, -1)
    curses.init_pair(2, curses.COLOR_YELLOW, -1)
    curses.init_pair(3, curses.COLOR_GREEN, -1)
    curses.init_pair(4, curses.COLOR_BLACK, curses.COLOR_WHITE)
    curses.init_pair(5, curses.COLOR_BLACK, curses.COLOR_YELLOW)

    idx = 0
    top = 0

    while True:
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        header = f" {len(matches)} matches  ↑/↓ or j/k navigate  Enter resume  q quit "
        stdscr.addnstr(0, 0, header.ljust(w), w, curses.color_pair(1) | curses.A_BOLD)

        # 3 lines per item: header, snippet, blank
        rows_per_item = 3
        visible = max(1, (h - 2) // rows_per_item)
        if idx < top:
            top = idx
        elif idx >= top + visible:
            top = idx - visible + 1

        for i in range(visible):
            j = top + i
            if j >= len(matches):
                break
            m = matches[j]
            y = 1 + i * rows_per_item
            selected = j == idx

            ts = m.timestamp[:19] if m.timestamp else "?"
            head = f"[{j+1}] {ts}  {m.role:<9}  {m.cwd}"
            head_attr = curses.color_pair(4) if selected else curses.color_pair(2)
            stdscr.addnstr(y, 0, head.ljust(w), w, head_attr | curses.A_BOLD)

            snippet = m.snippet
            if y + 1 < h:
                # render snippet with match highlighted
                avail = w - 2
                s, e = m.match_start, m.match_end
                # truncate snippet to width preserving match if possible
                if len(snippet) > avail:
                    # center on match
                    half = avail // 2
                    start = max(0, s - half)
                    end = start + avail
                    if end > len(snippet):
                        end = len(snippet)
                        start = max(0, end - avail)
                    snippet_view = snippet[start:end]
                    s_view = max(0, s - start)
                    e_view = max(s_view, min(len(snippet_view), e - start))
                else:
                    snippet_view = snippet
                    s_view, e_view = s, e

                base_attr = curses.color_pair(3) if selected else 0
                hl_attr = curses.color_pair(5) | curses.A_BOLD
                stdscr.addnstr(y + 1, 2, snippet_view[:s_view], avail, base_attr)
                pos = 2 + len(snippet_view[:s_view])
                if pos < w and s_view < e_view:
                    stdscr.addnstr(y + 1, pos, snippet_view[s_view:e_view], max(0, w - pos), hl_attr)
                    pos += len(snippet_view[s_view:e_view])
                if pos < w:
                    stdscr.addnstr(y + 1, pos, snippet_view[e_view:], max(0, w - pos), base_attr)

        stdscr.refresh()
        key = stdscr.getch()
        if key in (ord("q"), 27):
            return None
        if key in (curses.KEY_UP, ord("k")):
            idx = max(0, idx - 1)
        elif key in (curses.KEY_DOWN, ord("j")):
            idx = min(len(matches) - 1, idx + 1)
        elif key in (curses.KEY_NPAGE,):
            idx = min(len(matches) - 1, idx + visible)
        elif key in (curses.KEY_PPAGE,):
            idx = max(0, idx - visible)
        elif key in (curses.KEY_HOME,):
            idx = 0
        elif key in (curses.KEY_END,):
            idx = len(matches) - 1
        elif key in (curses.KEY_ENTER, 10, 13):
            return matches[idx]


def resume(match: Match) -> None:
    cwd = match.cwd if match.cwd and Path(match.cwd).is_dir() else os.getcwd()
    os.chdir(cwd)
    print(f"Resuming session {match.session_id}", file=sys.stderr)
    print(f"  cwd: {cwd}", file=sys.stderr)
    os.execvp("claude", ["claude", "--resume", match.session_id])


def main() -> int:
    ap = argparse.ArgumentParser(description="Search ~/.claude/projects jsonl logs and resume picked chat.")
    ap.add_argument("query", help="search term (literal unless --regex)")
    ap.add_argument("--regex", action="store_true", help="treat query as regex")
    ap.add_argument("--case-sensitive", action="store_true", help="case-sensitive match")
    ap.add_argument("--limit", type=int, default=200, help="max matches to display (default 200)")
    ap.add_argument("--print", action="store_true", help="print results, do not open picker")
    args = ap.parse_args()

    if not PROJECTS_DIR.is_dir():
        print(f"no projects dir at {PROJECTS_DIR}", file=sys.stderr)
        return 1

    matches = search_all(args.query, args.regex, args.case_sensitive)
    if not matches:
        print("no matches", file=sys.stderr)
        return 1
    matches = matches[: args.limit]

    if args.print:
        for i, m in enumerate(matches, 1):
            print(f"[{i}] {m.timestamp[:19]}  {m.session_id}  {m.cwd}")
            print(f"    {m.snippet}")
        return 0

    picked = curses.wrapper(picker, matches)
    if picked is None:
        return 130
    resume(picked)
    return 0


if __name__ == "__main__":
    sys.exit(main())
