# Device 1 integration notes

1. Copy the `data/` directory into the game project's root. Do not copy or replace Device 4's `tools/qa/` files.
2. Load:
   - `data/story/story.json`
   - `data/characters/characters.json`
   - `data/dialogue/dialogue.json`
   - `data/clues/clues.json`
   - `data/puzzles/puzzles.json`
3. Keep a dictionary keyed by each object's `id`. Example: `dialogue_by_id["dlg_level_1"]`.
4. For each level, follow `story.levels[].sequence` in ascending `step` order:
   - If `dialogue_id` exists, show those lines in order.
   - Add each `clue_ids` entry to the player's journal once.
   - If `puzzle_id` exists, instantiate the matching puzzle UI and compare the player's answer with `solution.answer` or the documented solution steps.
   - Unlock the next level only when its required sequence is complete.
5. Treat all dialogue and clues as optional discovery unless the sequence explicitly requires a puzzle or evidence chain. Do not block progression on every optional clue.
6. The JSON is engine-independent. Godot: parse with `JSON.parse_string()` and check the result is a Dictionary/Array. Unity: parse with the project's chosen JSON parser; no new runtime service is needed.
7. Do not hardcode narrative text in gameplay scripts when an ID exists. Use the ID and load the text from JSON.
8. Keep the resurrection rule as narrative/gameplay state data. The final proxy decision must only be accepted after the complete evidence bundle is sent and Dev's voluntary choice is recorded.
9. Do not let Device 1 modify this package's source files during integration; report requested changes to Device 3.
