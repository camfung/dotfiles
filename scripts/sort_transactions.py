#!/usr/bin/env python3
"""Sort transaction.json log entries chronologically.

Each entry is a multi-line block starting with a logcat header:
    logcat_xx:MM-DD HH:MM:SS.mmm PID TID LEVEL TAG: message...
Continuation lines belong to the preceding header.
"""

import argparse
import re
from pathlib import Path

HEADER_RE = re.compile(
    r"^logcat_[a-z]+:(?P<ts>\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+)"
)


def parse_blocks(text: str):
    blocks = []
    current_ts = None
    current_lines: list[str] = []
    for line in text.splitlines(keepends=True):
        m = HEADER_RE.match(line)
        if m:
            if current_lines:
                blocks.append((current_ts, current_lines))
            current_ts = m.group("ts")
            current_lines = [line]
        else:
            current_lines.append(line)
    if current_lines:
        blocks.append((current_ts, current_lines))
    return blocks


def main():
    parser = argparse.ArgumentParser(
        description="Sort transaction.json log entries chronologically."
    )
    parser.add_argument("src", type=Path, help="input transaction log file")
    parser.add_argument(
        "dest",
        type=Path,
        nargs="?",
        default=None,
        help="output sorted log file (defaults to src)",
    )
    args = parser.parse_args()
    if args.dest is None:
        args.dest = args.src

    text = args.src.read_text()
    blocks = parse_blocks(text)

    preamble = [b for b in blocks if b[0] is None]
    entries = [b for b in blocks if b[0] is not None]

    # Stable sort by timestamp string — works because format is fixed-width
    # and all entries fall in same year.
    entries.sort(key=lambda b: b[0])

    out = []
    for _, lines in preamble + entries:
        out.extend(lines)

    args.dest.write_text("".join(out))
    print(f"sorted {len(entries)} entries -> {args.dest}")


if __name__ == "__main__":
    main()
