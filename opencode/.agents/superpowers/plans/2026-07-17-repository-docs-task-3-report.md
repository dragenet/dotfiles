# Task 3 Implementation Report: repository-docs

**Date:** 2026-07-20
**Commit:** dd08644
**Branch:** master

## Scope

Implement Task 3 from `2026-07-17-repository-docs.md`:
1. Create `opencode/scripts/test-repository-docs.sh`
2. Active-path parity for `~/.config/opencode`
3. Run all validations

## Implementation

### 1. Test Script: `opencode/scripts/test-repository-docs.sh`

Self-contained, disposable test harness (35 assertions, all passing):

- **Fixture setup:** `mktemp -d` + trap cleanup, bare Git fixture with 2 commits + annotated tag
- **Input validation (14 tests):** rejects empty ref, abbreviated SHA, leading-dash, `^{}`, `~`, `?`, `*`, `[`, user-info HTTPS, non-git SSH user, `file://`, `http://`
- **Resolution/path/manifest (10 tests):** annotated tag→40-hex commit, detached HEAD, clean status, valid JSON manifest, no credential material, EEXIST conflict
- **Graphify preinstalled (4 tests):** CLI found, outside snapshot, extract succeeds, graph.json valid JSON
- **Immutable contract (3 tests):** snapshot intact, manifest intact, under disposable root
- **Fixture integrity (2 tests):** execution sentinel exists, content hash unchanged after workflow
- **Zero writes to real `$HOME/.agents/repositories`:** `HOME` redirected to `/tmp` root

### 2. Active-Path Parity

**Pre-existing parity** — no changes needed:

| File | Staged | Live | Status |
|------|--------|------|--------|
| `agents/repository-docs.md` | `opencode/` | `~/.config/opencode/` | ✅ Identical |
| `agents/graphify.md` | `opencode/` | `~/.config/opencode/` | ✅ Identical |
| `opencode.jsonc` agent `repository-docs` | Lines 560-613 | Lines 560-613 | ✅ Identical |
| `opencode.jsonc` command `repository-docs` | Lines 615-621 | Lines 615-621 | ✅ Identical |
| `external_directory: ~/.agents/repositories/**` | Agent-scoped | Agent-scoped | ✅ Both allow |

No deployment, symlink, or bootstrap changes performed.

### 3. Validation Results

| Command | Result |
|---------|--------|
| `python3 -c "import json; json.load(open('opencode/opencode.jsonc'))"` | `valid` |
| `python3 -c "import json, os; json.load(open(os.path.expanduser('~/.config/opencode/opencode.jsonc'))); print('valid')"` | `valid` |
| `bash opencode/scripts/check-skill-whitelists.sh` | `PASS` (122 entries, 5 orphans) |
| `bash opencode/scripts/test-repository-docs.sh` | `PASS` (35/35) |

### Concerns

None. All validations pass, parity is already established.

---

## Remediation (2026-07-20)

Task3 review findings addressed:

| # | Finding | Severity | Resolution | File |
|---|---------|----------|-----------|------|
| 1 | Missing Graphify skips instead of failing | Important | `_fail` on missing CLI, no skip | `scripts/test-repository-docs.sh:345-347` |
| 2 | No staged/live config drift assertions | Important | Added 9 structural assertions: agent frontmatter identity (repository-docs, graphify), command binding, permission objects (skill, external_directory), route exclusivity, graphify task allowlist | `scripts/check-skill-whitelists.sh` |
| 3 | No fixture modification sentinel | Minor | Added execution sentinel + SHA-256 content hash assertion proving test workflow doesn't modify repository content | `scripts/test-repository-docs.sh` |
| 4 | Public smoke command missing `--preinstalled` | Minor | Corrected `graphify extract . --out .agents` → `graphify extract . --out .agents --preinstalled` | `skill/repository-docs/SKILL.md:360-361` |
| 5 | Report: live JSON validation uses bare `~` path | Minor | Fixed to `os.path.expanduser`, reran, confirmed `valid`; updated commit to `dd08644` | `.agents/superpowers/plans/2026-07-17-repository-docs-task-3-report.md` |

### Post-Remediation Validation

| Command | Result |
|---------|--------|
| `bash -n opencode/scripts/check-skill-whitelists.sh` | syntax OK |
| `bash -n opencode/scripts/test-repository-docs.sh` | syntax OK |
| `python3 -c "import json; json.load(open('opencode/opencode.jsonc'))"` | `valid` |
| `python3 -c "import json, os; json.load(open(os.path.expanduser('~/.config/opencode/opencode.jsonc')))"` | `valid` |
| `bash opencode/scripts/check-skill-whitelists.sh` | `PASS` (122 entries, 5 orphans) |
| `bash opencode/scripts/test-repository-docs.sh` | `PASS` (35/35) |

All checks pass. No deployment, symlink, or bootstrap changes.