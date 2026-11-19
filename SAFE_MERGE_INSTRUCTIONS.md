# Safe integration instructions

This is a Device 3 overlay for the existing Pixel-Forge repository.

## Copy these paths into the existing repository root
- `data/` -> repository root `data/`
- `tools/story_validation/` -> repository root `tools/story_validation/`
- `docs/DATA_SCHEMA_DEVICE3.md` -> repository root `docs/`
- `docs/INTEGRATION_DEVICE1.md` -> repository root `docs/`
- `docs/DEVICE3_README.md` -> repository root `docs/`

## Do not overwrite
- `README.md` at repository root (Device 4 owns the existing one)
- `tools/qa/` (Device 4 QA toolkit)
- Existing `docs/` and `reports/` files

## Validate after copying
From repository root:
`python tools/story_validation/validate_story.py`

This validates Device 3 JSON structure and cross-references. It does not test engine runtime behavior.

## Narrative clarification
The Butcher and Strategist complete their respective named target lists before Arin meets them. Arin witnesses their acceptance and Warden-recorded return; he does not kill them. Arin's own contract is completed by Dev's informed, voluntary action against the original named handler. This keeps the proxy clause consistent and avoids treating boss defeat as a contract condition.
