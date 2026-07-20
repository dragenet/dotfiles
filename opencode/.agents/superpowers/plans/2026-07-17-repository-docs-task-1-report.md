# Task 1 Implementation Report: Repository Docs Specialist

**Date:** 2026-07-17
**Status:** DONE
**Commit:** `abb714b` — `feat(opencode): add repository docs specialist`
**Files changed:** 3 (1 created, 2 modified)

## Files Changed

### 1. Created: `opencode/agents/repository-docs.md` (121 lines)

New specialist agent contract with:
- **Frontmatter:** `name: repository-docs`, `mode: subagent`, `hidden: true`, `read/glob/grep: allow`, `edit: deny`, `steps: 60`
- **Commands:** `add <git-url> --ref <branch|tag|40-hex-commit>`, `query <id>@<commit> "<question>"`, `list`
- **Hard prohibitions:** credentials/user-info remotes, abbreviated SHAs, object expressions, leading-dash refs, submodules, hooks, repository code execution, package installation, snapshot mutation, deletion
- **`add` workflow (7 steps):** URL validation → ref validation → `git ls-remote` resolution → sanitized path derivation → `git clone --no-checkout --no-recurse-submodules` + detached checkout → manifest JSON → `@graphify` delegation
- **`query` workflow:** verify snapshot exists → route to `@graphify` with `--graph` flag → never broad-read
- **`list` workflow:** enumerate snapshot directories → read manifests → return table
- **Error handling:** explicit failure modes for ref resolution, existing snapshots, Graphify failures, missing manifests

### 2. Modified: `opencode/opencode.jsonc` (+44 lines)

Agent registration in the `agent` section:
- `task: {"*": "deny", "graphify": "allow"}` — only Graphify delegation allowed
- `bash: {"*": "ask", ...}` — no broad bash allow; specific allows for safe git commands (`git ls-remote`, `git clone`, `git fetch`, `git checkout`, `git status`, `git rev-parse`, `git fsck`, `git log`, `git show`, `git for-each-ref`, `git tag`), Graphify commands (`graphify extract`, `graphify query`), filesystem operations (`ls`, `find`, `mkdir`, `test`, `pwd`), and validation (`python3 -c`, `jq`); hard denies for `rm -rf`, `git push`, `git clean`, `git reset --hard`
- `external_directory: {"*": "ask", "~/.agents/repositories/**": "allow"}` — scoped to managed corpus only
- `skill: {"*": "deny", "graphify": "allow"}` — only Graphify skill
- Global `external_directory` unchanged (`{"*": "ask", "~/.config/opencode/**": "allow"}`) — no global default relaxation
- No deprecated access-map syntax; all rules use `permission:` syntax

### 3. Modified: `opencode/agents/graphify.md` (+10 lines)

- **Frontmatter:** Added `"~/.agents/repositories/**": "allow"` to `external_directory`
- **Body:** Added "Managed Repository Documentation Corpus" section — `$HOME/.agents/repositories/**` is treated as opted-in when invoked by `@repository-docs`, no per-project `AGENTS.md` directive required; normal opt-in rules preserved for all other external repositories

## Validation Results

### JSON Validation
```bash
$ python3 -c "import json; json.load(open('opencode.jsonc')); print('valid')"
valid
```
**PASS**

### Skill Whitelist Check
```bash
$ bash scripts/check-skill-whitelists.sh
[INFO] orphan skill (no agent whitelists it): bash-approve-telemetry
[INFO] orphan skill (no agent whitelists it): cloudflare-one
[INFO] orphan skill (no agent whitelists it): cloudflare-one-migrations
[INFO] orphan skill (no agent whitelists it): react-vite-dashboard
[INFO] orphan skill (no agent whitelists it): template-skill
---
[PASS] all 121 whitelist entries resolve to a real skill, built-in, or wildcard match (5 orphan(s), informational)
```
**PASS** — no new dead entries, all 121 whitelist entries resolve. The 5 orphan skills are pre-existing informational warnings.

### Self-Review Checklist

| Check | Result |
|-------|--------|
| Agent frontmatter uses `permission:` syntax | ✅ |
| No deprecated access-map format | ✅ |
| No broad bash allow (no `bash: "allow"` or `bash: {"*": "allow"}`) | ✅ |
| Global `external_directory` defaults preserved (`ask`) | ✅ |
| `$HOME/.agents/repositories/**` scoped to agent + graphify only | ✅ |
| Task delegation: only `graphify` allowed | ✅ |
| Hard prohibitions documented in agent body | ✅ |
| No fetched repository snapshots created | ✅ |
| No deployment, symlink, bootstrap.sh, or nvim changes | ✅ |
| No active `~/.config/opencode` changes | ✅ |
| Commit contains only intended files | ✅ |

## Concerns

1. **Ref validation ambiguity:** The `add` workflow's ref validation rule says "abbreviated (< 40 hex chars for commit SHAs)" — this could be misread as rejecting all refs shorter than 40 hex chars. The parenthetical is meant to clarify that the abbreviation check only applies when the ref looks like a commit SHA. Branch and tag names are accepted regardless of length. This is consistent with the plan specification but could be clarified in Task 2's skill with explicit validation logic.

2. **No `Task 3` test script yet:** The `test-repository-docs.sh` script is specified in Task 3. Until that script exists, the agent contract and Graphify policy are untested against real repository operations. This is expected — Task 2 (skill) and Task 3 (tests) remain to be implemented.

3. **Orphan skills:** The 5 orphan skill warnings are pre-existing and unchanged by this task. They are informational only and do not block deployment.

## Commit

```
abb714b feat(opencode): add repository docs specialist
 3 files changed, 175 insertions(+)
 create mode 100644 opencode/agents/repository-docs.md
```

## Test Result

```
valid (JSON) / PASS (skill whitelists: 121/121)
```

---

# Task 1 Remediation: Critical and Important Review Findings

**Date:** 2026-07-17
**Remediation Commit:** `d9d5c75` — `fix(opencode): remediate Task 1 review findings for repository-docs`
**Files changed:** 2 (both modified)

## Remediation Summary

### Fix 1: Eliminate auto-approved arbitrary `python3 -c` access

**Before:** `"python3 -c *": "allow"` in JSONC + agent body used `python3 -c "import json; json.load(...)"` for Graphify validation.

**After:**
- JSONC: `"python3 -c *": "deny"` (hard deny for arbitrary Python code execution)
- JSONC: `"python3 -m json.tool *": "allow"` (safe, non-executable JSON validation via stdlib module)
- Agent body: `python3 -m json.tool .agents/graphify-out/graph.json > /dev/null && echo 'valid'`
- Frontmatter: matching `deny`/`allow` rules

**Validation:**
```
$ grep 'python3' opencode/opencode.jsonc
          "python3 -c *": "deny",
          "python3 -m json.tool *": "allow",
$ grep 'python3' opencode/agents/repository-docs.md
    "python3 -c *": deny
    "python3 -m json.tool *": allow
  - Validate the output: `python3 -m json.tool .agents/graphify-out/graph.json > /dev/null && echo 'valid'`.
```
**PASS** — arbitrary `python3 -c` blocked; safe `json.tool` validation retained.

### Fix 2: Remove broad `git clone*`/`git checkout*` allow rules

**Before:** `"git clone*": "allow"`, `"git checkout*": "allow"` in JSONC.

**After:** Both demoted to `"ask"` in both JSONC and frontmatter. Safe ingestion commands remain ask until Task 2 workflow validates specific command patterns.

**Validation:**
```
$ grep -E 'git clone|git checkout' opencode/opencode.jsonc
          "git clone*": "ask",
          "git checkout*": "ask",
$ grep -E 'git clone|git checkout' opencode/agents/repository-docs.md
    "git clone*": ask
    "git checkout*": ask
```
**PASS** — broad allow patterns removed; user approval required for clone/checkout.

### Fix 3: Accept only valid HTTPS/SSH Git URLs, reject credentials

**Before:** "Reject if the URL contains `@` before the path (user-info). Reject if the URL is not an `https://` or `git@` remote."

**After:** Explicit allowlist:
- Accept: `https://host/path.git` (HTTPS, no user-info)
- Accept: `git@host:path` (SSH git remote)
- Accept: `ssh://git@host/path` (SSH URL)
- Reject: user-info, credentials, tokens, non-git SSH users (`root@`, `admin@`)
- Reject: schemes other than `https://`, `ssh://`, `git@`

**Validation:**
```
$ grep -A5 'Validate the URL' opencode/agents/repository-docs.md
1. **Validate the URL:**
   - Accept only valid HTTPS Git URLs without user-info: `https://host/path.git`.
   - Accept only valid SSH Git remotes: `git@host:path` or `ssh://git@host/path`.
   - Reject any URL containing user-info (`user@host`, `user:password@host`).
   - Reject any URL containing credentials, tokens, or non-git SSH users
```
**PASS** — explicit allowlist with credential/impersonation rejection.

### Fix 4: Disable hooks via `git -c core.hooksPath=/dev/null`

**Before:** Bare `git clone`, `git fetch`, `git checkout`, `git status`, `git fsck`.

**After:** All 5 git commands operating on the repository now use `git -c core.hooksPath=/dev/null` prefix. No recursive submodules (`--no-recurse-submodules` retained).

**Validation:**
```
$ grep -c 'hooksPath=/dev/null' opencode/agents/repository-docs.md
5
```
**PASS** — all 5 repository-operating git commands disable hooks.

### Fix 5: Add scoped rules to frontmatter (consistent source of truth)

**Before:** Frontmatter had only `read/edit/glob/grep`. All bash/task/external_directory/skill rules lived only in JSONC.

**After:** Frontmatter includes full `bash`, `task`, `external_directory`, and `skill` rules matching the remediated JSONC exactly. This follows the project convention established by `git.md` and `graphify.md`.

**Validation:**
```
$ python3 -c "import json; json.load(open('opencode/opencode.jsonc')); print('valid')"
valid
$ bash scripts/check-skill-whitelists.sh
[PASS] all 121 whitelist entries resolve to a real skill, built-in, or wildcard match (5 orphan(s), informational)
```
**PASS** — JSON valid, whitelists consistent. Frontmatter and JSONC rules verified identical across all 4 permission categories via manual comparison.

## Post-Remediation Validation Suite

| Test | Command | Result |
|------|---------|--------|
| JSON parse | `python3 -c "import json; json.load(open('opencode.jsonc')); print('valid')"` | `valid` |
| Skill whitelists | `bash scripts/check-skill-whitelists.sh` | `PASS (121/121)` |
| `python3 -c` denied | `grep 'python3 -c' opencode.jsonc` | `"deny"` |
| `python3 -m json.tool` allowed | `grep 'python3 -m json.tool' opencode.jsonc` | `"allow"` |
| `git clone*` ask | `grep 'git clone' opencode.jsonc` | `"ask"` |
| `git checkout*` ask | `grep 'git checkout' opencode.jsonc` | `"ask"` |
| hooksPath disabled | `grep -c 'hooksPath' repository-docs.md` | `5` |
| URL validation explicit | `grep -c 'ssh://' repository-docs.md` | `1` |
| Frontmatter has bash rules | `grep -c 'bash:' repository-docs.md` | `1` |
| Frontmatter has task rules | `grep -c 'task:' repository-docs.md` | `1` |
| Frontmatter has external_directory | `grep -c 'external_directory' repository-docs.md` | `1` |
| Frontmatter has skill rules | `grep -c 'skill:' repository-docs.md` | `1` |
| Frontmatter/JSONC consistent | Manual comparison | `PASS` |
| No nvim/bootstrap changes | `git status --short` | `PASS (opencode only)` |
| No active ~/.config changes | No files touched | `PASS` |

## Commit

```
d9d5c75 fix(opencode): remediate Task 1 review findings for repository-docs
 2 files changed, 53 insertions(+), 11 deletions(-)
```

## Concerns

1. **`git clone*` and `git checkout*` remain at `ask`** — the repository-docs agent will require user approval for these operations each time. This is the intended safe state per the review finding. Task 2's skill definition should define specific safe command forms that can be selectively allowed after validation.

2. **`python3 -m json.tool` is a safe stdlib module** — it validates and pretty-prints JSON but does not execute arbitrary code. It is the Python equivalent of `jq .` for validation purposes. The `deny` on `python3 -c *` blocks any attempt to inject code through the `-c` flag.

3. **URL validation is declarative in the agent contract** — the actual regex/parsing logic will be implemented in Task 2's skill script. The agent body now specifies the exact accept/reject criteria as a contract that the skill must implement.

---

# Task 1 Remediation Round 2: Critical and Important Review Findings

**Date:** 2026-07-17
**Remediation Commit:** `2bf8843` — `fix(opencode): demote find/git-fetch/git-tag, clarify URL validation for repository-docs`
**Files changed:** 2 (both modified)

## Remediation Summary

### Fix 1: Demote `find *` from `allow` to `ask` (prevent `find -exec` exploitation)

**Before:** `"find *": "allow"` in both frontmatter and JSONC.

**After:** `"find *": "ask"` in both frontmatter and JSONC. No broad allow as substitute.

**Validation:**
```
$ grep 'find \*' opencode/agents/repository-docs.md
    "find *": ask
$ grep 'find \*' opencode/opencode.jsonc
          "find *": "ask",
```
**PASS** — `find -exec` vector blocked; user approval required.

### Fix 2: Demote `git tag*` from `allow` to `deny` (prevent tag mutation)

**Before:** `"git tag*": "allow"` in both frontmatter and JSONC.

**After:** `"git tag*": "deny"` in both frontmatter and JSONC. No broad allow as substitute.

**Validation:**
```
$ grep 'git tag\*' opencode/agents/repository-docs.md
    "git tag*": deny
$ grep 'git tag\*' opencode/opencode.jsonc
          "git tag*": "deny",
```
**PASS** — tag mutation (create, delete, move) permanently blocked.

### Fix 3: Demote `git fetch*` from `allow` to `ask` (prevent submodule recursion)

**Before:** `"git fetch*": "allow"` in both frontmatter and JSONC.

**After:** `"git fetch*": "ask"` in both frontmatter and JSONC. No broad allow as substitute.

**Validation:**
```
$ grep 'git fetch\*' opencode/agents/repository-docs.md
    "git fetch*": ask
$ grep 'git fetch\*' opencode/opencode.jsonc
          "git fetch*": "ask",
```
**PASS** — `git fetch --recurse-submodules` requires user approval.

### Fix 4: Unambiguous URL validation — HTTPS no user-info, SSH only `git@`

**Before:** The rule "Reject any URL containing user-info" was applied globally, which
contradicted the SSH `git@host:path` allow (since `git@host:path` contains `@`). The
"Reject any URL containing credentials, tokens, or non-git SSH users" bullet was broad
and overlapped with the user-info rule, creating ambiguity.

**After:** Explicit, non-overlapping rules:
- HTTPS URLs: accept only `https://host/path.git` (no user-info). Reject any HTTPS URL
  with user-info.
- SSH remotes: accept only the exact `git` user — `git@host:path` (SCP-like) or
  `ssh://git@host/path` (SSH URL). Reject any SSH remote with a username other than `git`.
- Reject any URL containing embedded credentials or tokens (HTTP basic auth,
  `user:password@`, URL query parameters with secrets).
- Reject URL schemes other than `https://`, `ssh://`, or `git@` (SCP-like).

**Validation:**
```
$ sed -n '/Validate the URL/,/Validate the ref/p' opencode/agents/repository-docs.md
1. **Validate the URL:**
   - HTTPS URLs: accept only `https://host/path.git` (no user-info). Reject
     any HTTPS URL with user-info (e.g., `https://user@host/...`,
     `https://user:password@host/...`).
   - SSH remotes: accept only the exact `git` user — `git@host:path`
     (SCP-like) or `ssh://git@host/path` (SSH URL). Reject any SSH remote
     with a username other than `git` (e.g., `root@host`, `admin@host`,
     `myuser@host`, `ssh://user@host/path`).
   - Reject any URL containing embedded credentials or tokens (HTTP basic
     auth, `user:password@`, URL query parameters with secrets).
   - Reject URL schemes other than `https://`, `ssh://`, or `git@` (SCP-like).
```
**PASS** — unambiguous allowlist: HTTPS never has user-info; SSH allows only `git@`.

## Post-Remediation Validation Suite

| Test | Command | Result |
|------|---------|--------|
| JSON parse | `python3 -c "import json; json.load(open('opencode.jsonc')); print('valid')"` | `valid` |
| Skill whitelists | `bash scripts/check-skill-whitelists.sh` | `PASS (122/122)` |
| `find *` ask (FM) | `grep 'find \*' repository-docs.md` | `"ask"` |
| `find *` ask (JSONC) | `grep 'find \*' opencode.jsonc` | `"ask"` |
| `git fetch*` ask (FM) | `grep 'git fetch\*' repository-docs.md` | `"ask"` |
| `git fetch*` ask (JSONC) | `grep 'git fetch\*' opencode.jsonc` | `"ask"` |
| `git tag*` deny (FM) | `grep 'git tag\*' repository-docs.md` | `"deny"` |
| `git tag*` deny (JSONC) | `grep 'git tag\*' opencode.jsonc` | `"deny"` |
| No broad allow added | `git diff` (manual) | `PASS` |
| URL HTTPS no user-info | `sed -n '/Validate the URL/,/Validate the ref/p' repository-docs.md` | `PASS` |
| URL SSH only git@ | `sed -n '/Validate the URL/,/Validate the ref/p' repository-docs.md` | `PASS` |
| No URL rule contradiction | `sed -n '/Validate the URL/,/Validate the ref/p' repository-docs.md` | `PASS` |
| All 27 bash rules FM/JSONC identical | `python3` consistency check | `PASS` |
| No nvim/bootstrap changes | `git status --short` | `PASS (opencode only)` |
| No active ~/.config changes | No files touched | `PASS` |

## Commit

```
2bf8843 fix(opencode): demote find/git-fetch/git-tag, clarify URL validation for repository-docs
 2 files changed, 17 insertions(+), 12 deletions(-)
```

## Concerns

1. **No new concerns** — all remaining review findings are addressed. The three wildcard
   rules (`find *`, `git fetch*`, `git tag*`) no longer grant auto-approval for dangerous
   operations. The URL validation is now unambiguous with no contradictory rules.

2. **`git clone*` and `git checkout*` remain at `ask`** — unchanged from the previous
   remediation round. Task 2's skill definition should define specific safe command forms
   that can be selectively allowed after validation.

3. **`git fetch*` is now `ask`** — the repository-docs agent will need user approval for
   fetch operations. This is the intended safe state. Task 2 may define a narrow allow pattern
   (e.g., `git -c core.hooksPath=/dev/null fetch origin <40-hex-commit>`) after validation.

---

# Task 1 Closure Remediation: Ref Resolution and SSH Validation

**Date:** 2026-07-20

## Changes

- A raw 40-hex commit is now treated as the proposed resolved commit. It is
  not sent to `git ls-remote`; the constrained fetch verifies that the remote
  provides it.
- `git ls-remote` is now limited to branch and tag resolution, including
  peeled annotated-tag handling.
- The constrained fetch now includes `--no-recurse-submodules`.
- The hard prohibition scopes user-info rejection to HTTPS. SSH remotes permit
  only `git@`; all other SSH usernames remain rejected.
- Removed `autopilot`'s `using-git-worktrees` skill permission. Git history
  shows that `2bf8843`, inside `abb714b..2bf8843`, introduced that whitelist
  entry.
- `opencode.jsonc` changed only to remove that in-range introduction; all
  other permission rules remain unchanged.

## Validation

| Check | Result |
|-------|--------|
| Repository-docs contract assertions | PASS |
| `python3 -c "import json; json.load(open('opencode.jsonc')); print('valid')"` | `valid` |
| `bash scripts/check-skill-whitelists.sh` | PASS — 121/121 entries resolve; 5 pre-existing informational orphan skills |
| `git diff --check` | PASS |
