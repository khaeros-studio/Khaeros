# Test Infrastructure

**Engine**: Godot 4.7.2 (pin 4.7)
**Test Framework**: gdUnit4 6.2.3 (`addons/gdUnit4/`, capital U)
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-11-13

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
```

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Running Tests

From the project root (Windows: `C:\Users\lucas\Godot\godot.cmd`; Git Bash: `godot`):

```bash
godot --headless --path . --import
godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

Run the import first: a fresh clone has no `.godot/` cache and the runner exits 1
having run nothing. Re-run it if the first import crashes on exit (seen on 4.7.x).

Exit codes: **0** all passed · **100** failures · **101** passed but orphan nodes
leaked (use `auto_free`) · **103** headless refused (`--ignoreHeadlessMode` missing) ·
**105** a test script does not parse · **1** runner did not load (no import).
`No test cases found` with exit 0 is **not** a pass.
Two `ERROR:` lines about the remote port `127.0.0.1:0` are expected.
Reports go to `reports/` (gitignored).

## Installing / updating gdUnit4

The addon is committed under `addons/gdUnit4/` (v6.2.3, from
`godot-gdunit-labs/gdUnit4`). The plugin is enabled in `project.godot`
(`[editor_plugins]`). To update: replace the folder with a newer release
(Asset Store in the editor since 4.7, or the GitHub release) and re-run the suite.
gdUnit4's README lists Godot up to 4.7.1 for 6.2.x; 4.7.2 is not listed but the
suite runs on it (verified locally 2026-11-13: smoke suite exit 0; a deliberately
failing test exit 100).

## Test Naming

- Godot: file `[system]_[feature]_test.gd`, function `test_[scenario]_[expected]`
  — `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`
- Every test is arrange / act / assert; wrap `Node`s in `auto_free()`.

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Retained screenshot of each screen touched | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging. If you protect `main`, require the
`Run GdUnit4 Tests` job check, not `test-results` (that check concludes success
even when a test fails).
