#!/usr/bin/env python3
"""Offline standard-library validator for Device 3 narrative JSON."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FILES = [
    ROOT / "data/characters/characters.json",
    ROOT / "data/dialogue/dialogue.json",
    ROOT / "data/clues/clues.json",
    ROOT / "data/puzzles/puzzles.json",
    ROOT / "data/story/story.json",
]
LEVEL_IDS = {f"level_{i}" for i in range(1, 6)}

def load(path):
    def no_duplicates(pairs):
        out = {}
        for key, value in pairs:
            if key in out:
                raise ValueError(f"duplicate JSON key: {key}")
            out[key] = value
        return out
    with path.open(encoding="utf-8") as f:
        return json.load(f, object_pairs_hook=no_duplicates)

def unique_ids(items, label):
    seen = set()
    for item in items:
        ident = item.get("id")
        if not isinstance(ident, str) or not ident:
            raise ValueError(f"{label}: missing/invalid id")
        if ident in seen:
            raise ValueError(f"{label}: duplicate id {ident}")
        seen.add(ident)
    return seen

def main():
    try:
        data = {p.name: load(p) for p in FILES}
        chars = data["characters.json"]["characters"]
        dialogs = data["dialogue.json"]["dialogue"]
        clues = data["clues.json"]["clues"]
        puzzles = data["puzzles.json"]["puzzles"]
        story = data["story.json"]
        char_ids = unique_ids(chars, "characters")
        dialog_ids = unique_ids(dialogs, "dialogue")
        clue_ids = unique_ids(clues, "clues")
        puzzle_ids = unique_ids(puzzles, "puzzles")
        levels = story["levels"]
        level_ids = unique_ids(levels, "levels")
        if level_ids != LEVEL_IDS:
            raise ValueError(f"expected exactly {sorted(LEVEL_IDS)}, got {sorted(level_ids)}")
        for d in dialogs:
            if d["level_id"] not in LEVEL_IDS: raise ValueError(f"{d['id']}: invalid level_id")
            if not d.get("lines"): raise ValueError(f"{d['id']}: no dialogue lines")
        for c in clues:
            if c["level_id"] not in LEVEL_IDS: raise ValueError(f"{c['id']}: invalid level_id")
        for p in puzzles:
            if p["level_id"] not in LEVEL_IDS: raise ValueError(f"{p['id']}: invalid level_id")
            if not p["solution"].get("steps") or not p["solution"].get("answer"):
                raise ValueError(f"{p['id']}: incomplete solution")
        for level in levels:
            if not isinstance(level.get("sequence"), list) or not level["sequence"]:
                raise ValueError(f"{level['id']}: missing sequence")
            for step in level["sequence"]:
                if "dialogue_id" in step and step["dialogue_id"] not in dialog_ids:
                    raise ValueError(f"{level['id']}: unknown dialogue {step['dialogue_id']}")
                for ident in step.get("clue_ids", []):
                    if ident not in clue_ids: raise ValueError(f"{level['id']}: unknown clue {ident}")
                if "puzzle_id" in step and step["puzzle_id"] not in puzzle_ids:
                    raise ValueError(f"{level['id']}: unknown puzzle {step['puzzle_id']}")
        print("PASS: 5 JSON files parsed; duplicate keys and IDs checked.")
        print(f"PASS: {len(chars)} characters, {len(dialogs)} dialogue sets, {len(clues)} clues, {len(puzzles)} puzzles.")
        print("PASS: all level, dialogue, clue and puzzle references resolve.")
        print("NOTE: This checks structure/references, not game-engine runtime behavior.")
        return 0
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
