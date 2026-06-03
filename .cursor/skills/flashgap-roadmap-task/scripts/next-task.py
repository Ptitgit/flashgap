#!/usr/bin/env python3
"""Print the next Flashgap roadmap task (first todo in epic order)."""

from __future__ import annotations

import re
import sys
from pathlib import Path

# Matches roadmap/README.md recommended flow (E8 after E5)
EPIC_DIRS = [
    "e1-infrastructure-vps",
    "e2-backend-albums-membres",
    "e3-backend-upload-reveal",
    "e4-mobile-onboarding",
    "e5-mobile-camera-hd",
    "e8-builds-distribution",
    "e6-mobile-upload-fiable",
    "e7-mobile-countdown-galerie",
    "e9-validation-e2e",
]

TASK_LINK_RE = re.compile(r"\]\(\./(E\d+-US\d+[^)]+\.md)\)")
STATUS_RE = re.compile(r"\*\*Statut\*\*\s*\|\s*`([^`]+)`")


def repo_root() -> Path:
    here = Path(__file__).resolve()
    for parent in here.parents:
        if (parent / "roadmap" / "README.md").exists():
            return parent
    raise SystemExit("Cannot find repo root (roadmap/README.md)")


def task_status(task_path: Path) -> str:
    text = task_path.read_text(encoding="utf-8")
    match = STATUS_RE.search(text)
    return match.group(1).strip() if match else "unknown"


def list_tasks(epic_dir: Path) -> list[str]:
    readme = epic_dir / "README.md"
    if not readme.exists():
        return []
    names: list[str] = []
    for match in TASK_LINK_RE.finditer(readme.read_text(encoding="utf-8")):
        names.append(match.group(1))
    return names


def main() -> int:
    root = repo_root()
    roadmap = root / "roadmap"

    for epic_name in EPIC_DIRS:
        epic_dir = roadmap / epic_name
        if not epic_dir.is_dir():
            continue
        for filename in list_tasks(epic_dir):
            task_path = epic_dir / filename
            if not task_path.exists():
                continue
            status = task_status(task_path)
            if status == "todo":
                print(task_path.relative_to(root))
                return 0
            if status == "in_progress":
                print(task_path.relative_to(root))
                print("# resume in_progress", file=sys.stderr)
                return 0

    print("NO_TASK: all roadmap tasks are done or blocked", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
