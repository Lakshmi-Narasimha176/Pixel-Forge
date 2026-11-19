# Device 3 data contract (schema version 1.0)

All files are UTF-8 JSON. IDs are stable, lowercase strings. Do not rename IDs after Device 1 starts referencing them.

## Files
- `data/characters/characters.json`: `{schema_version, characters[]}`. Character fields: `id`, `name`, `role`, `alive_at_start`, `backstory`, `traits[]`, `goal`, `secret`.
- `data/dialogue/dialogue.json`: `{schema_version, dialogue[]}`. Dialogue fields: `id`, `level_id`, `lines[]`; each line has `speaker`, `text`.
- `data/clues/clues.json`: `{schema_version, clues[]}`. Clue fields: `id`, `level_id`, `description`, `meaning`, `type`.
- `data/puzzles/puzzles.json`: `{schema_version, puzzles[]}`. Puzzle fields: `id`, `level_id`, `name`, `type`, `objective`, `inputs[]`, `solution{steps[], answer}`, `hint`, `failure_feedback`.
- `data/story/story.json`: `{schema_version, game_id, title, theme, resurrection_rule, levels[]}`. Each level has `id`, `number`, `name`, `purpose`, `sequence[]`, `reveal`, `next_mystery`; level-specific optional fields include `persistent_connection` and `resolution`.

## Reference conventions
- `level_id` references `level_1` through `level_5`.
- Story sequence `dialogue_id`, `clue_ids`, and `puzzle_id` reference IDs in their corresponding files.
- Character IDs are `char_protagonist`, `char_butcher`, `char_strategist`, `char_friend`, `char_warden`.
- The story JSON is the source of truth for level order and resurrection rules.
- `type` and `role` are descriptive strings; Device 1 should branch on stable IDs, not display text.

## Runtime integration
Load these files as data; do not execute JSON. Cache parsed data at startup. Trigger dialogue by `dialogue_id`, display clues by `clue_ids`, and start puzzles by `puzzle_id`. Store discovered clue IDs in a set so the same clue cannot be awarded repeatedly. Keep progression state separate from the source JSON. See `INTEGRATION_DEVICE1.md`.
