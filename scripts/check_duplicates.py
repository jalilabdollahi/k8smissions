#!/usr/bin/env python3
"""Find template-made or near-duplicate levels.

Compares every pair of levels, file by file, after blanking out names and
numbers (levels made from one template differ only in those). Also flags
boilerplate sentences that appear in many levels.

Usage: scripts/check_duplicates.py [filters...] [--code 0.75] [--text 0.5]
A filter limits which levels are reported; they are still compared against all
levels. Exit 1 if anything is flagged.
"""

from __future__ import annotations

import argparse
import re
from collections import Counter
from itertools import combinations
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
CODE = ("validate.sh", "solution.sh", "setup.sh", "broken.yaml")
TEXT = ("hint-1.txt", "hint-2.txt", "hint-3.txt", "reveal.md", "debrief.md", "common-mistakes.md")


def normalize(text: str, code: bool) -> list[str]:
    if code:
        text = "\n".join(l for l in text.splitlines() if not l.strip().startswith("#"))
    text = text.lower()
    text = re.sub(r"\d+", " n ", text)
    text = re.sub(r"[a-z0-9]+(-[a-z0-9]+)+", " name ", text)  # resource names like web-api-7f9
    return re.findall(r"[a-z]+|[^\sa-z]", text)


def shingles(tokens: list[str], n: int = 6) -> set[str]:
    return {" ".join(tokens[i:i + n]) for i in range(max(0, len(tokens) - n + 1))}


def jaccard(a: set, b: set) -> float:
    return len(a & b) / len(a | b) if a and b else 0.0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("filters", nargs="*")
    ap.add_argument("--code", type=float, default=0.75)
    ap.add_argument("--text", type=float, default=0.5)
    args = ap.parse_args()

    levels = sorted(p.parent for p in (REPO / "modules").glob("*/*/mission.yaml"))
    rid = {l: f"{l.parent.name}/{l.name}" for l in levels}
    wanted = {l for l in levels if not args.filters or any(f in rid[l] for f in args.filters)}
    flagged = 0

    for name in CODE + TEXT:
        is_code = name in CODE
        sh = {}
        for l in levels:
            f = l / name
            if f.exists():
                s = shingles(normalize(f.read_text(errors="replace"), is_code))
                if len(s) >= 8:  # tiny files (e.g. a one-line hint) are not comparable
                    sh[l] = s
        limit = args.code if is_code else args.text
        for a, b in combinations(sh, 2):
            if a not in wanted and b not in wanted:
                continue
            j = jaccard(sh[a], sh[b])
            if j >= limit:
                flagged += 1
                print(f"SIMILAR {j:.2f}  {name}: {rid[a]}  ~  {rid[b]}")

    sentences = Counter()
    for l in levels:
        for name in TEXT:
            f = l / name
            if f.exists():
                for s in {x.strip() for x in re.split(r"(?<=[.!?])\s+|\n", f.read_text()) if len(x.strip()) > 50}:
                    sentences[s] += 1
    for s, n in sentences.most_common():
        if n < 4:
            break
        hits = [rid[l] for l in levels if l in wanted and any(s in (l / t).read_text() for t in TEXT if (l / t).exists())]
        if hits:
            flagged += 1
            print(f"BOILERPLATE x{n}: \"{s[:110]}\"")

    for f in (REPO / "scripts").glob("*template*.py"):
        flagged += 1
        print(f"TEMPLATE SCRIPT still present: {f.relative_to(REPO)}")
    print(f"\n{flagged} issue(s)")
    return 1 if flagged else 0


if __name__ == "__main__":
    raise SystemExit(main())
