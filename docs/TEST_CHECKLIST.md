# Manual QA checklist

Record build/commit, tester, date, device RAM, resolution, and result. Mark PASS only after execution.

## Every level
- [ ] Level loads from intended entry point; no missing-resource errors.
- [ ] Player spawns at intended position and can move/look.
- [ ] Collision prevents walking through walls/floors/doors.
- [ ] Required interaction prompt appears and works.
- [ ] Objective and clue are discoverable without soft-lock.
- [ ] Audio/visual cues trigger once at intended event.
- [ ] Pause/resume and restart behave correctly.
- [ ] Exit/transition reaches the correct next state.
- [ ] No console errors; no persistent frame-rate collapse.

## Level-specific progression
- [ ] 1. The Awakening: opening sequence completes; first objective is understandable; exit unlocks.
- [ ] 2. The Butcher: required clues/interactions can be found; encounter can be completed; exit unlocks.
- [ ] 3. The Strategist: puzzle accepts correct solution; rejects incorrect solution; reset/retry works.
- [ ] 4. The Impossible Return: return/loop logic behaves as authored; player cannot become permanently trapped.
- [ ] 5. The Betrayer: final reveal and ending trigger; completion state is recorded; restart/new game works.

## Cross-level progression
- [ ] Fresh game starts at Level 1.
- [ ] Each level unlocks only after its required condition.
- [ ] Level transitions preserve only intended state.
- [ ] Loading/restarting does not bypass puzzle or progression conditions.
- [ ] All five levels are reachable in one clean playthrough.
- [ ] Ending is reachable and reproducible.

For each failure: capture level, exact steps, expected result, actual result, screenshot/log, severity, and reproducibility.
