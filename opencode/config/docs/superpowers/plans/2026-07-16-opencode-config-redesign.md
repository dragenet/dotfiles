# OpenCode Config Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the raw-vendored `~/.dotfiles/opencode/config/` tree into a complete, loadable, cost/performance-optimized OpenCode global config per the approved design (`docs/superpowers/specs/2026-07-16-opencode-config-redesign-design.md`).

**Architecture:** A single shared `opencode.json` (no models) + submodule-vendored superpowers/skills + a per-machine `opencode.local.json` model layer, a 23-agent roster, six plugins, a graphify orchestrator/worker pair, and CLI-based context7. Each phase leaves the config loadable.

**Tech Stack:** OpenCode 1.18.2, JSON/JSONC config, Markdown agent/skill files, git submodules, Bash verification scripts, `uv`-installed `graphifyy` CLI.

## Global Constraints

- Config root is `~/.dotfiles/opencode/config/` — the future `~/.config/opencode` symlink target. All relative paths below are from this root unless stated.
- **Do NOT** touch the live `~/.config/opencode`, `~/.dotfiles/bootstrap.sh`, or `infra-flux`. No symlink, no `opencode.local.json` with real secrets, no `git commit` unless the user explicitly asks.
- Shared `opencode.json` carries **no** `model`/`small_model`/machine `provider` block.
- Do not use legacy boolean `tools:` configuration. Migrate every existing agent
  file and `opencode.json` tool override to the current `permission:` format,
  preserving its effective allow/deny behavior.
- No qwen models. No `:discounted` kilo variants. No `kilo/anthropic|openai/*` passthrough for company code.
- Superproject git repo is `~/.dotfiles` (remote `github.com:dragenet/dotfiles`); submodules register in `~/.dotfiles/.gitmodules` with `opencode/config/<name>` paths.
- Verification runs use `OPENCODE_CONFIG` pointed at a throwaway local layer where a model is required; never commit secrets.
- Do not modify the unrelated in-flight nvim changes in `git status`.

---

## Phase 1 — Foundation & vendoring

Registers submodules inside `config/`, wires the superpowers plugin + skill discovery symlinks, and vendors the graphify skill, so the existing `opencode.json` skill whitelists resolve on disk.

### Task 1.1: Reconcile the inert `.gitmodules` and register submodules under `config/`

**Files:**
- Delete: `~/.dotfiles/opencode/.gitmodules` (inert — wrong location, git ignores it)
- Modify: `~/.dotfiles/.gitmodules` (created/appended by `git submodule add`)
- Create (submodule checkouts): `config/superpowers/`, `config/anthropics-skills/`, `config/cloudflare-skills/`, `config/stitch-skills/`, `config/awesome-agent-skills/`, `config/jenkins-cli/`

**Interfaces:**
- Produces: on-disk submodule trees at `config/<name>/` that later symlink + skill-whitelist tasks consume.

- [ ] **Step 1: Confirm the inert file's contents, then remove it**

Run: `cat ~/.dotfiles/opencode/.gitmodules && git -C ~/.dotfiles rm --cached -q opencode/.gitmodules 2>/dev/null; rm -f ~/.dotfiles/opencode/.gitmodules`
Expected: prints the six `[submodule ...]` blocks, then removes the misplaced file.

- [ ] **Step 2: Add all six submodules under `opencode/config/`**

Run (from `~/.dotfiles`):
```bash
git submodule add https://github.com/obra/superpowers.git opencode/config/superpowers
git submodule add https://github.com/anthropics/skills.git opencode/config/anthropics-skills
git submodule add https://github.com/cloudflare/skills.git opencode/config/cloudflare-skills
git submodule add https://github.com/google-labs-code/stitch-skills.git opencode/config/stitch-skills
git submodule add https://github.com/VoltAgent/awesome-agent-skills.git opencode/config/awesome-agent-skills
git submodule add https://github.com/avivsinai/jenkins-cli.git opencode/config/jenkins-cli
```
Expected: each clones into `opencode/config/<name>` and appends an entry to `~/.dotfiles/.gitmodules`.

- [ ] **Step 3: Verify all submodules are initialized**

Run: `git -C ~/.dotfiles submodule status | grep opencode/config`
Expected: six lines, each starting with a commit hash and **no** leading `-` (a leading `-` means uninitialized).

- [ ] **Step 4: Commit boundary (only if the user has authorized commits)**

```bash
git -C ~/.dotfiles add .gitmodules opencode/config/superpowers opencode/config/anthropics-skills opencode/config/cloudflare-skills opencode/config/stitch-skills opencode/config/awesome-agent-skills opencode/config/jenkins-cli
git -C ~/.dotfiles commit -m "feat(opencode): register skill submodules under config/"
```
Otherwise skip and leave staged.

### Task 1.2: Create the superpowers plugin symlink

**Files:**
- Create: `plugins/superpowers.js` → `../superpowers/.opencode/plugins/superpowers.js`

- [ ] **Step 1: Verify the submodule exposes the plugin entry**

Run: `ls config/superpowers/.opencode/plugins/superpowers.js` (from repo root `~/.dotfiles/opencode`)
Expected: the file exists. If the path differs, run `find config/superpowers -name 'superpowers.js' -path '*plugin*'` and use the real path in Step 2.

- [ ] **Step 2: Create the symlink**

Run (from `config/`):
```bash
mkdir -p plugins
ln -sf ../superpowers/.opencode/plugins/superpowers.js plugins/superpowers.js
```

- [ ] **Step 3: Verify it resolves**

Run: `readlink plugins/superpowers.js && test -f plugins/superpowers.js && echo OK`
Expected: prints the target path then `OK`.

### Task 1.3: Create skill discovery symlinks

**Files:**
- Create: `skills/superpowers` → `../superpowers/skills`
- Create: `skills/anthropics` → `../anthropics-skills/skills`
- Create: `skills/cloudflare-skills` → `../cloudflare-skills`
- Create: `skills/stitch-skills` → `../stitch-skills`
- Create: `skills/awesome-agent-skills` → `../awesome-agent-skills`
- Create: `skills/jenkins-cli` → `../jenkins-cli/skills`

- [ ] **Step 1: Confirm each submodule's skill dir path**

Run (from `config/`): `for d in superpowers/skills anthropics-skills/skills cloudflare-skills stitch-skills awesome-agent-skills jenkins-cli/skills; do echo -n "$d: "; test -d "$d" && echo yes || echo NO; done`
Expected: each prints `yes`. For any `NO`, inspect that submodule's tree and adjust the symlink target in Step 2.

- [ ] **Step 2: Create the symlinks**

Run (from `config/`):
```bash
mkdir -p skills
ln -sfn ../superpowers/skills skills/superpowers
ln -sfn ../anthropics-skills/skills skills/anthropics
ln -sfn ../cloudflare-skills skills/cloudflare-skills
ln -sfn ../stitch-skills skills/stitch-skills
ln -sfn ../awesome-agent-skills skills/awesome-agent-skills
ln -sfn ../jenkins-cli/skills skills/jenkins-cli
```

- [ ] **Step 3: Verify all resolve to directories**

Run (from `config/`): `for l in skills/*; do echo -n "$l -> "; readlink "$l"; test -d "$l" && echo ok || echo BROKEN; done`
Expected: every line ends `ok`.

### Task 1.4: Vendor the graphify skill

**Files:**
- Create: `skill/graphify/SKILL.md` + `skill/graphify/references/*` (copied from `~/Projects/fux-infra/infra-flux/.opencode/skills/graphify/`, excluding `node_modules/` and `.graphify_version`)

- [ ] **Step 1: Copy the skill (SKILL.md + references only)**

Run (from `config/`):
```bash
mkdir -p skill/graphify
rsync -a --exclude node_modules --exclude '.graphify_*' \
  ~/Projects/fux-infra/infra-flux/.opencode/skills/graphify/SKILL.md \
  ~/Projects/fux-infra/infra-flux/.opencode/skills/graphify/references \
  skill/graphify/
```

- [ ] **Step 2: Verify the skill frontmatter resolves**

Run (from `config/`): `head -4 skill/graphify/SKILL.md && ls skill/graphify/references | wc -l`
Expected: frontmatter with `name: graphify`, and 8 reference files.

### Task 1.5: Verify skill whitelists resolve

**Files:**
- Test: `scripts/check-skill-whitelists.sh`

- [ ] **Step 1: Run the whitelist checker**

Run (from `config/`): `bash scripts/check-skill-whitelists.sh; echo "exit=$?"`
Expected: `exit=0`. Any `[ERROR]` lines name a whitelisted skill that doesn't resolve — fix by correcting the symlink target (Task 1.3) or the whitelist entry in `opencode.json`. `[INFO]` orphan lines are acceptable.

---

## Phase 2 — Model layer

Produces the two per-machine `opencode.local.json` templates and the rewritten `model-selection.md`. These are gitignored templates (committed as `*.example` so they're tracked without leaking machine specifics).

### Task 2.1: Create the personal model layer template

**Files:**
- Create: `opencode.local.personal.example.json`

**Interfaces:**
- Produces: `agent.<name>.model` + `model`/`small_model` for the personal machine, consumed by `OPENCODE_CONFIG` at runtime.

- [ ] **Step 1: Write the personal template**

Create `opencode.local.personal.example.json` with the §3 personal column verbatim:
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-6",
  "small_model": "opencode-go/minimax-m3",
  "agent": {
    "architect":        { "model": "anthropic/claude-opus-4-8" },
    "debugger":         { "model": "anthropic/claude-opus-4-8" },
    "autopilot":        { "model": "anthropic/claude-sonnet-4-6" },
    "general":          { "model": "anthropic/claude-sonnet-4-6" },
    "devops":           { "model": "openai/gpt-5.6-terra" },
    "skill-smith":      { "model": "openai/gpt-5.6-terra" },
    "jenkins":          { "model": "anthropic/claude-sonnet-4-6" },
    "webdebugger":      { "model": "anthropic/claude-sonnet-4-6" },
    "coder":            { "model": "opencode-go/deepseek-v4-pro" },
    "cloudflare":       { "model": "opencode-go/deepseek-v4-pro" },
    "frontend":         { "model": "opencode-go/deepseek-v4-pro" },
    "stitch":           { "model": "opencode-go/deepseek-v4-pro" },
    "writer":           { "model": "anthropic/claude-sonnet-4-6" },
    "webresearcher":    { "model": "openai/gpt-5.6-luna" },
    "web-fast-context": { "model": "opencode-go/deepseek-v4-flash" },
    "webscraper":       { "model": "opencode-go/deepseek-v4-flash" },
    "webmonitor":       { "model": "opencode-go/deepseek-v4-flash" },
    "ha":               { "model": "opencode-go/deepseek-v4-flash" },
    "jira":             { "model": "opencode-go/deepseek-v4-flash" },
    "stitch-mcp":       { "model": "opencode-go/deepseek-v4-flash" },
    "graphify":         { "model": "opencode-go/deepseek-v4-flash" },
    "graphify-extractor": { "model": "opencode-go/deepseek-v4-flash" },
    "git":              { "model": "opencode-go/minimax-m3" }
  }
}
```
> Note: reasoning-effort variants (§3) are set interactively via the model picker or a `reasoningEffort` field once §15 item 1 confirms the exact config key on 1.18.2; leave them out of the template until verified.

- [ ] **Step 2: Validate every model ID resolves on this machine**

Run: `for m in anthropic/claude-sonnet-4-6 anthropic/claude-opus-4-8 openai/gpt-5.6-terra openai/gpt-5.6-luna opencode-go/deepseek-v4-pro opencode-go/deepseek-v4-flash opencode-go/minimax-m3; do opencode models 2>/dev/null | grep -qx "$m" && echo "OK $m" || echo "MISSING $m"; done`
Expected: all `OK`. Any `MISSING` means the provider isn't authed on this machine (expected on the work machine — see Task 2.2).

### Task 2.2: Create the work (NDA-safe) model layer template

**Files:**
- Create: `opencode.local.work.example.json`

- [ ] **Step 1: Write the work template (kilo NDA-safe column from §3)**

Create `opencode.local.work.example.json`:
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "kilo/z-ai/glm-5.1",
  "small_model": "kilo/minimax/minimax-m3",
  "provider": {
    "kilo": { "options": { "headers": { "X-KiloCode-OrganizationId": "{file:secrets/kilo.org}" } } }
  },
  "agent": {
    "architect":        { "model": "kilo/z-ai/glm-5.1" },
    "debugger":         { "model": "kilo/z-ai/glm-5.1" },
    "autopilot":        { "model": "kilo/z-ai/glm-5.1" },
    "general":          { "model": "kilo/z-ai/glm-5.1" },
    "devops":           { "model": "kilo/z-ai/glm-5.1" },
    "skill-smith":      { "model": "kilo/z-ai/glm-5.1" },
    "jenkins":          { "model": "kilo/z-ai/glm-5.1" },
    "webdebugger":      { "model": "kilo/z-ai/glm-5.1" },
    "coder":            { "model": "kilo/deepseek/deepseek-v4-pro" },
    "cloudflare":       { "model": "kilo/deepseek/deepseek-v4-pro" },
    "frontend":         { "model": "kilo/deepseek/deepseek-v4-pro" },
    "stitch":           { "model": "kilo/deepseek/deepseek-v4-pro" },
    "writer":           { "model": "kilo/z-ai/glm-5.1" },
    "webresearcher":    { "model": "kilo/z-ai/glm-5.1" },
    "web-fast-context": { "model": "kilo/deepseek/deepseek-v4-flash" },
    "webscraper":       { "model": "kilo/deepseek/deepseek-v4-flash" },
    "webmonitor":       { "model": "kilo/deepseek/deepseek-v4-flash" },
    "ha":               { "model": "kilo/deepseek/deepseek-v4-flash" },
    "jira":             { "model": "kilo/deepseek/deepseek-v4-flash" },
    "stitch-mcp":       { "model": "kilo/deepseek/deepseek-v4-flash" },
    "graphify":         { "model": "kilo/deepseek/deepseek-v4-flash" },
    "graphify-extractor": { "model": "kilo/deepseek/deepseek-v4-flash" },
    "git":              { "model": "kilo/minimax/minimax-m3" }
  }
}
```

- [ ] **Step 2: Add `opencode.local.json` + `secrets/kilo.org` to gitignore coverage**

Run: `grep -q 'opencode.local.json' .gitignore && echo "already ignored" || echo "opencode.local.json" >> .gitignore`
Expected: `already ignored` (the base `.gitignore` already lists it) — the `*.example` templates stay tracked.

### Task 2.3: Rewrite `docs/model-selection.md`

**Files:**
- Modify: `docs/model-selection.md` (replace the colleague's Kilo-only content)

- [ ] **Step 1: Replace with the §3 table + justifications**

Rewrite `docs/model-selection.md` to document: the four-provider setup, the two-machine layer mechanism, the full per-agent table (both columns + variants), the per-choice justifications from spec §3, the NDA rule, the no-qwen rule, and the GLM latency fallback. Use the spec §3 content as the source of truth.

- [ ] **Step 2: Verify no qwen / no discounted references remain**

Run: `grep -niE 'qwen|:discounted' docs/model-selection.md; echo "exit=$?"`
Expected: no matches (`exit=1` from grep).

---

## Phase 3 — Roster & permissions

Adds the four new agents, switches bash defaults toward autonomy, and applies the global permission rules. The 19 base agents already have blocks in `opencode.json` — this phase only edits what the design changes.

### Task 3.1: Add global permission rules (global-config-readable, ctx7, task)

**Files:**
- Modify: `opencode.json` (top-level `permission` block, lines ~16-42)

- [ ] **Step 1: Add the ctx7 bash allows, global-config read, and external_directory**

In `opencode.json` `permission`, add to the `bash` object: `"npx ctx7*": "allow"`, `"ctx7*": "allow"`. Add sibling keys:
```json
"read": { "*": "allow" },
"external_directory": { "*": "ask", "~/.config/opencode/**": "allow", "~/.dotfiles/opencode/**": "allow" }
```
Keep `edit: "ask"` and the existing `task: { "autopilot": "deny" }`.

- [ ] **Step 2: Verify JSON parses**

Run (from `config/`): `python3 -c "import json;json.load(open('opencode.json'));print('valid')"`
Expected: `valid`.

### Task 3.2: Create the `git` agent file + block

**Files:**
- Create: `agents/git.md`
- Modify: `opencode.json` (add `agent.git` block)

- [ ] **Step 1: Write `agents/git.md`** with the autonomous permission set from spec §9 (allow add/commit/restore/switch/checkout/stash/tag/merge/pull/fetch; ask push/reset/rebase/force-with-lease/checkout--file; deny force-push/reset--hard/clean/rebase-i/filter-branch/checkout-.), `edit: deny`, `task: {"*":"deny"}`, `skill: allow`, `steps: 40`. Base it on the current live `~/.config/opencode/agents/git.md`, promoting the `ask` ops to `allow` per §9. Put `"*"` first, general allows next, specific denies last.

- [ ] **Step 2: Verify the frontmatter parses and push is ask, force-push deny**

Run (from `config/`): `grep -E 'git push' agents/git.md`
Expected: a `"git push*": "ask"` (or `"git push": "ask"`) line AND a `"git push --force*": "deny"` line, with the deny appearing after the ask.

### Task 3.3: Create `agents/web-fast-context.md` + block

**Files:**
- Create: `agents/web-fast-context.md`
- Modify: `opencode.json` (add `agent.web-fast-context`)

- [ ] **Step 1: Copy the live agent, then sharpen the description per §11**

Copy from `~/.config/opencode/agents/web-fast-context.md`, then set the description to the §11 wording (raw websearch/webfetch, no Firecrawl, defers to @webresearcher/@webscraper). Keep `permission`: only `webfetch: allow`, `websearch: allow`, everything else deny, `hidden: true`, `steps: 18`.

- [ ] **Step 2: Add the opencode.json block** with `task: {"*":"deny"}` and `skill: {"*":"deny"}` (pure operator).

- [ ] **Step 3: Verify** — Run: `grep -c 'firecrawl' agents/web-fast-context.md` → Expected: it appears only in the "no Firecrawl / use @webscraper" guidance, never as an enabled tool.

### Task 3.4: Add the `webresearcher` reciprocal pointer

**Files:**
- Modify: `agents/webresearcher.md` (append the §11 pointer to `@web-fast-context`)

- [ ] **Step 1:** Append the sentence: "If the caller only needs a quick single fact or version/flag lookup (not multi-source search + synthesis), tell them to use @web-fast-context — it's faster and spends no Firecrawl credits."

- [ ] **Step 2: Verify** — Run: `grep -c 'web-fast-context' agents/webresearcher.md` → Expected: `1`.

### Task 3.5: Loosen global bash default toward autonomy

**Files:**
- Modify: `opencode.json` (top-level `permission.bash`)

- [ ] **Step 1:** Keep `bash."*": "ask"` as the fail-safe floor (per spec §8 — claude-bash-approve auto-approves the safe set; native stays `ask` so a plugin miss fails to a prompt). Add explicit hard-deny entries: `"rm -rf*": "deny"`, `"dd *": "deny"`, `"mkfs*": "deny"`, `"reboot*": "deny"`, `"shutdown*": "deny"`, `"poweroff*": "deny"`, `"git push --force*": "deny"`, `"terraform destroy*": "deny"`.

- [ ] **Step 2: Verify JSON parses** — Run: `python3 -c "import json;json.load(open('opencode.json'));print('valid')"` → Expected: `valid`.

### Task 3.6: Verify the full roster resolves

- [ ] **Step 1:** Run: `python3 -c "import json;d=json.load(open('opencode.json'));print(sorted(d['agent']))"`
Expected: includes `git`, `web-fast-context`, `plan`, `autopilot`, and the base 19 (graphify agents added in Phase 5).

- [ ] **Step 2:** Run: `bash scripts/check-skill-whitelists.sh; echo "exit=$?"` → Expected: `exit=0`.

---

## Phase 4 — Plugins

Adds the four remaining plugins (`mnemosyne` + `anthropic-oauth` already present).

### Task 4.1: Add caffeinate + background-agents to the plugin array

**Files:**
- Modify: `opencode.json` (`plugin` array)

- [ ] **Step 1:** Set the array to:
```json
"plugin": [
  "opencode-mnemosyne",
  "opencode-anthropic-oauth",
  "opencode-caffeinate",
  "opencode-background-agents"
]
```
> Use the k-dylan caffeinate fork and the kdcokenny background-agents original (strict read-only) per spec §6. If npm names differ for the fork, pin the exact package/git spec here.

- [ ] **Step 2: Verify parse** — `python3 -c "import json;json.load(open('opencode.json'));print('valid')"` → `valid`.

### Task 4.2: Configure DCP

**Files:**
- Create: `dcp.jsonc`
- Modify: `opencode.json` (`plugin` array — add `@tarquinen/opencode-dcp`)

- [ ] **Step 1:** Install per its CLI: `opencode plugin @tarquinen/opencode-dcp@latest --global` (or add to the array). Create `dcp.jsonc` with per-provider `compress.maxContextLimit`/`minContextLimit` for `opencode-go`, `kilo`, `openai`, `anthropic`; keep native `compaction` in `opencode.json` as the fallback floor.

- [ ] **Step 2: Verify** — `python3 -c "import json,re,sys;s=open('dcp.jsonc').read();json.loads(re.sub(r'//.*','',s));print('valid')"` → `valid`.

### Task 4.3: Install claude-bash-approve (testing)

**Files:**
- External: installs opencode plugin files via its installer

- [ ] **Step 1:** `python3 install.py install --target opencode --scope both` from a checkout of `mariusvniekerk/claude-bash-approve`.

- [ ] **Step 2: Verify the §15 items** — run a known-safe command in an opencode session (expect no prompt) and a known-dangerous one (expect block); confirm `categories.yaml` location and that per-agent native `allow` composition behaves as documented. Record findings in the design's §15.

---

## Phase 5 — graphify flow

Adds the orchestrator + worker agents and the per-project opt-in doc template.

### Task 5.1: Create `agents/graphify.md` + block

**Files:**
- Create: `agents/graphify.md`
- Modify: `opencode.json` (`agent.graphify` + whitelist `graphify` skill to it and to `architect`/`autopilot`/`general`)

- [ ] **Step 1: Write `agents/graphify.md`** — role from spec §10 (detect→AST→dispatch workers→merge/cluster→query). `permission`: `bash: true` (needs the CLI; global hard-denies still apply), `read: allow`, `edit: deny`, `task: {"*":"deny","graphify-extractor":"allow"}`, `skill: {"*":"deny","using-superpowers":"allow","graphify":"allow"}`.

- [ ] **Step 2: Whitelist the graphify skill for orchestrators** — in `opencode.json`, add `"graphify": "allow"` to the `skill` maps of `architect`, `autopilot`, `general`.

- [ ] **Step 3: Verify** — `bash scripts/check-skill-whitelists.sh; echo exit=$?` → `exit=0` (the vendored `skill/graphify/SKILL.md` from Task 1.4 resolves the new whitelist entries).

### Task 5.2: Create `agents/graphify-extractor.md` + block

**Files:**
- Create: `agents/graphify-extractor.md`
- Modify: `opencode.json` (`agent.graphify-extractor`)

- [ ] **Step 1: Write the worker** — spec §10: `hidden: true`, `read: allow`, `edit: allow` (**must be write-capable** — writes `graphify-out/.graphify_chunk_NN.json`, the success signal), `bash: allow` (for the python merge/write blocks), `task: {"*":"deny"}`, `skill: {"*":"deny"}`. Prompt: extract entities/relationships for the assigned chunk per `references/extraction-spec.md`, write the chunk JSON, return the JSON.

- [ ] **Step 2: Verify write-capability** — Run: `grep -E 'edit:' agents/graphify-extractor.md` → Expected: `edit: allow` (NOT deny — a read-only worker silently breaks extraction).

### Task 5.3: Create the per-project opt-in doc template

**Files:**
- Create: `docs/graphify-project-optin.md`

- [ ] **Step 1:** Write a short template a project's `AGENTS.md` copies when opting in: graphify enabled, `graphify-out/` location, routing rule ("repo-structure questions → @graphify; don't broad-read"), post-commit hook installed (`graphify hook install`), when to run manual `--update` (doc/image changes).

- [ ] **Step 2: Smoke-test graphify on a tiny corpus**

Run (throwaway): `cd /tmp && mkdir -p gtest/src && printf 'def f():\n return 1\n' > gtest/src/a.py && cd gtest && graphify . --no-viz 2>&1 | tail -5`
Expected: a `graphify-out/graph.json` is produced (installs `graphifyy` via `uv` on first run). Clean up `/tmp/gtest` after.

---

## Phase 6 — context7 CLI, AGENTS.md, docs

Switches context7 off MCP, updates the global instruction file, and finalizes docs.

### Task 6.1: Remove context7 MCP, keep firecrawl/others

**Files:**
- Modify: `opencode.json` (delete the `mcp.context7` block; delete `secrets/context7.key` need)

- [ ] **Step 1:** Delete the `mcp.context7` object (lines ~515-522 in the base). Leave `playwright`, `chrome-devtools`, `firecrawl`, `homeassistant`, `jira`, `stitch`, `github`(disabled), `pdf-reader`(disabled), `dart`(disabled), and add the live config's `tmux-mcp` block.

- [ ] **Step 2: Verify** — `python3 -c "import json;d=json.load(open('opencode.json'));print('context7' in d['mcp'], 'tmux-mcp' in d['mcp'])"` → Expected: `False True`.

### Task 6.2: Write the AGENTS.md context7 CLI block + web-agent routing

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1:** Add a `## context7` section documenting `npx ctx7@latest <library> <query>` usage (from the live config's AGENTS.md), noting the `bash` allow added in Task 3.1. Add a `## Web agents` routing block with the four-way split from spec §11.

- [ ] **Step 2: Verify** — `grep -c 'ctx7' AGENTS.md` → Expected: ≥1; `grep -c 'web-fast-context' AGENTS.md` → Expected: ≥1.

### Task 6.3: Update `docs/memory-rules.md` + `docs/dev-guide.md`

**Files:**
- Modify: `docs/memory-rules.md` (review against final roster), `docs/dev-guide.md` (add graphify agents, note CLI context7, correct the roster count to 23+plan)

- [ ] **Step 1:** Edit both docs for accuracy against the final config.

- [ ] **Step 2: Verify roster count** — `grep -c 'graphify' docs/dev-guide.md` → Expected: ≥1.

### Task 6.4: Final full-config verification

- [ ] **Step 1:** `python3 -c "import json;json.load(open('opencode.json'));print('opencode.json valid')"` → valid.
- [ ] **Step 2:** `bash scripts/check-skill-whitelists.sh; echo exit=$?` → `exit=0`.
- [ ] **Step 3:** With a throwaway `OPENCODE_CONFIG=$PWD/opencode.local.personal.example.json`, run `OPENCODE_CONFIG=... opencode models >/dev/null 2>&1; echo "load exit=$?"` → Expected: `0` (config loads without a parse/agent-resolution error).
- [ ] **Step 4:** Confirm the live `~/.config/opencode` and `~/.dotfiles/bootstrap.sh` are unchanged: `git -C ~/.dotfiles status --short | grep -E 'bootstrap.sh' ; echo "clean if empty above"`.

---

## Self-review notes

- **Spec coverage:** §1 (Phases scope), §2 (P3/P5 roster), §3 (P2 model layer), §4 (P1 vendoring), §5 (P6.1/6.2 context7 CLI), §6 (P4 plugins), §7 (P4 mnemosyne present), §8 (P3.1/3.5 permissions + P4.3 bash-approve), §9 (P3.2 git), §10 (P5 graphify), §11 (P3.3/3.4/6.2 web agents), §12 (autopilot block already in base — verified in P3.6), §13 (P6.1 MCP), §14 (deferred — enforced by Global Constraints), §15 (P4.3 + verification steps).
- **Deferred by design:** exact reasoning-effort config key (§15 item 1) gates the variant fields in P2 templates; MCP enable/disable matrix finalized in P6.1.
- **Model IDs** are the exact `opencode models`-verified strings from spec §3.
