# Windows release verification

- [ ] Export preset targets Windows x86_64 (confirm with team).
- [ ] Exported executable and required `.pck`/data files are present.
- [ ] Test from a clean extracted folder, not the development workspace.
- [ ] Test on a Windows account without Godot installed.
- [ ] Confirm no absolute development-machine paths.
- [ ] Confirm all five levels and ending work in exported build.
- [ ] Confirm keyboard/mouse controls and window mode.
- [ ] Confirm no network connection is required.
- [ ] Check antivirus/quarantine false positives if applicable.
- [ ] Include README, controls, credits, licence/attribution list.
- [ ] Record version, build date, commit/hash, tester and known issues.
- [ ] Zip final folder; extract that ZIP elsewhere and launch again.
- [ ] Keep one untouched final release archive and verify its SHA-256.

Do not claim release-ready until the clean-folder test succeeds.
