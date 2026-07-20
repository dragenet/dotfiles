# Task 3 Implementation Report: repository-docs

**Date:** 2026-07-20
**Commit:** (pending)
**Branch:** master

## Scope

Implement Task 3 from `2026-07-17-repository-docs.md`:
1. Create `opencode/scripts/test-repository-docs.sh`
2. Active-path parity for `~/.config/opencode`
3. Run all validations

## Implementation

### 1. Test Script: `opencode/scripts/test-repository-docs.sh`

Self-contained, disposable test harness (33 assertions, all passing):

- **Fixture setup:** `mktemp -d` + trap cleanup, bare Git fixture with 2 commits + annotated tag
- **Input validation (14 tests):** rejects empty ref, abbreviated SHA, leading-dash, `^{}`, `~`, `?`, `*`, `[`, user-info HTTPS, non-git SSH user, `file://`, `http://`
- **Resolution/path/manifest (10 tests):** annotated tag→40-hex commit, detached HEAD, clean status, valid JSON manifest, no credential material, EEXIST conflict
- **Graphify preinstalled (4 tests):** CLI found, outside snapshot, extract succeeds, graph.json valid JSON
- **Immutable contract (3 tests):** snapshot intact, manifest intact, under disposable root
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
| `python3 -c "import json; json.load(open('~/.config/opencode/opencode.jsonc'))"` | `valid` |
| `bash opencode/scripts/check-skill-whitelists.sh` | `PASS` (122 entries, 5 orphans) |
| `bash opencode/scripts/test-repository-docs.sh` | `PASS` (33/33) |

### Concerns

None. All validations pass, parity is already established.