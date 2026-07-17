# Design: OpenCode global config redesign

**Date:** 2026-07-16
**Status:** Approved design — pending spec review, then implementation plan
**Staging location:** `~/.dotfiles/opencode/` (vendored base from
`jabbas/opencode-config`, see `VENDORED_FROM.md`)
**Deploy target (later):** `~/.config/opencode` (currently the live, untouched config)

---

## 1. Goal & scope

Rebuild the global OpenCode config into a clean, portable, cost/performance-
optimized setup, using `jabbas/opencode-config` as the architectural base,
adapted for this user's four providers and workflow.

**In scope:** the global config tree under `~/.dotfiles/opencode/` —
agent roster, per-machine model layer, providers, plugins, permissions, skills/
superpowers vendoring, context7, memory, autopilot, graphify, and the web-agent
family.

**Explicitly OUT of scope:**
- `infra-flux` and its local `.opencode/` — untouched. It will later be
  refactored to align with *this* setup, not the reverse.
- Deploying to `~/.config/opencode`: no symlink, no `bootstrap.sh` change, no
  `opencode.local.jsonc`, no secrets population, no commit — all deferred to a
  later step (§14).

---

## 2. Agent roster

Keep the **entire** colleague roster (no trimming) plus this user's additions.
**24 custom agents + built-in `plan`.**

Inherited from base (19): `general` (`agents/default.md`), `coder`,
`architect`, `autopilot`, `debugger`, `devops`, `jenkins`, `ha`, `webdebugger`,
`webscraper`, `webresearcher`, `webmonitor`, `cloudflare`, `frontend`, `stitch`,
`stitch-mcp`, `writer`, `skill-smith`, `jira`.

Added by this user (5): `web-fast-context` (already migrated to the live
config), `git` (already in the live config), and **new** `graphify` +
`graphify-extractor` (§10), plus `reviewer`.

Built-in: `plan` (read-only, defined in `opencode.jsonc`).

**Permissions format:** use `permission:` everywhere. OpenCode deprecated the
legacy boolean `tools:` format; simple agents use shorthand permission values
and safety-sensitive agents (`git`, `graphify`, `autopilot`, MCP operators)
use detailed pattern maps where needed.

---

## 3. Model & provider layer

The shared, tracked `opencode.jsonc` carries **no** `model`/`small_model`/
machine-specific `provider` block. Those live in a per-machine, gitignored
`opencode.local.jsonc`, deep-merged via the `OPENCODE_CONFIG` env var.

### Providers

| Provider | Personal machine | Work machine |
|---|---|---|
| `opencode-go` | primary open-model gateway | not used |
| `kilo` | not used | primary gateway, **NDA-safe** |
| `anthropic` | frontier reasoning/text | configured, **not** default on any agent (NDA) |
| `openai` (ChatGPT **Plus / OAuth** — Codex line only) | frontier coding/tooling | configured, **not** default on any agent (NDA) |

**NDA rule (work):** company code routes only through `kilo` open models.
Frontier providers stay configured for explicit non-sensitive opt-in but are the
default on no agent. Never `kilo/anthropic/*` or `kilo/openai/*` passthrough for
company code; never `:discounted` kilo variants (data-training + crippled
tool-calling). **No qwen models anywhere** (hang / no-answer during agentic loops).

**openai availability:** the `openai` provider is ChatGPT-Plus OAuth (verified:
`api.openai.com/v1/models` → 403 `Missing scopes: api.model.read`). Only the
agentic-coding line is reachable: `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.5`,
`gpt-5.6-luna`, `gpt-5.6-terra`, `gpt-5.6-sol`. API-only models are NOT usable.

**"deepseek-v4-pro" is the implementation model** on both machines (identical
family across `opencode-go` and `kilo`, so zero personal↔work skew on the
highest-volume role).

**Provider version skew** (baked into per-machine picks; opencode-go leads kilo):
GLM `5.2` (go) vs `5.1` (kilo); Kimi `k2.7-code` (go) vs `k2.6` (kilo).

### Variants

"Variant" = reasoning effort, from each model's `reasoning_options`. Effort
levels differ per model: anthropic sonnet `low/medium/high/max`; opus
`+xhigh`; opencode-go deepseek/glm `high/max` only; kilo glm-5.1/deepseek
`toggle + high/xhigh`; minimax/kimi `toggle` only. Effort scales with reasoning
depth needed, not importance.

### Defaults

| Slot | Personal | Work (NDA-safe) |
|---|---|---|
| `model` | `anthropic/claude-sonnet-4-6` · medium | `kilo/z-ai/glm-5.1` · on |
| `small_model` | `opencode-go/minimax-m3` · off | `kilo/minimax/minimax-m3` · off |

### Per-agent assignments

| Agent | Personal (variant) | Work NDA-safe (variant) | Justification |
|---|---|---|---|
| `architect` | `anthropic/claude-opus-4-8` · high | `kilo/z-ai/glm-5.1` · high | Deepest design/ADR/plan reasoning, no bash. Opus top reasoner; high (not max) — design rarely needs xhigh. Work: GLM #1 open long-horizon. |
| `debugger` | `anthropic/claude-opus-4-8` · high | `kilo/z-ai/glm-5.1` · high | Cross-stack root-cause, long logs. Work: GLM #1 open Terminal-Bench. |
| `autopilot` | `anthropic/claude-sonnet-4-6` · **medium** | `kilo/z-ai/glm-5.1` · on | Thinks then delegates to subagents; heavy work is in the workers, so mid-tier orchestrator is cost-right. GLM has no "medium" (on/high only). |
| `general` | `anthropic/claude-sonnet-4-6` · medium | `kilo/z-ai/glm-5.1` · on | Default dispatch target; reliable all-rounder. |
| `devops` | `opencode-go/deepseek-v4-pro` · high | `kilo/deepseek/deepseek-v4-pro` · high | Infrastructure implementation uses the same cost-effective implementation model as `coder`, with the specialized DevOps prompt and project safety gates preserving the infrastructure domain boundary. |
| `skill-smith` | `openai/gpt-5.6-terra` · medium | `kilo/z-ai/glm-5.1` · on | Behavior code + MCP servers = agentic coding + tool-calling. Work: GLM #1 open tool-calling. |
| `jenkins` | `anthropic/claude-sonnet-4-6` · low | `kilo/z-ai/glm-5.1` · off | `jk` CLI controller ops — deterministic; reliability > reasoning. |
| `webdebugger` | `anthropic/claude-sonnet-4-6` · low | `kilo/z-ai/glm-5.1` · off | Interprets DOM/network/console via Playwright MCP; comprehension not planning. |
| `reviewer` | `anthropic/claude-opus-4-8` · high | `kilo/z-ai/glm-5.1` · high | Read-only adversarial review across code, infrastructure, configuration, and documentation. High reasoning catches cross-file and operational regressions before handoff. |
| `coder` | `opencode-go/deepseek-v4-pro` · high | `kilo/deepseek/deepseek-v4-pro` · high | Implementation model. Polyglot code; v4-pro strong SWE reasoning. |
| `cloudflare` | `opencode-go/deepseek-v4-pro` · high | `kilo/deepseek/deepseek-v4-pro` · high | Workers/wrangler/DO = pure code transformation. |
| `frontend` | `opencode-go/deepseek-v4-pro` · high | `kilo/deepseek/deepseek-v4-pro` · high | Component/UI build = implementation. |
| `stitch` | `opencode-go/deepseek-v4-pro` · high | `kilo/deepseek/deepseek-v4-pro` · high | Stitch design→code = code generation. |
| `writer` | `anthropic/claude-sonnet-4-6` · low | `kilo/z-ai/glm-5.1` · off | Docs/specs/docx-pptx-pdf = prose quality, minimal step-reasoning. No qwen. |
| `webresearcher` | `openai/gpt-5.6-luna` · medium | `kilo/z-ai/glm-5.1` · on | High-volume web reads; luna ($1/$6) is the "fast/affordable" fit, 1.05M ctx for big crawls. No qwen. |
| `web-fast-context` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | Quick sourced facts in parallel; cheap. |
| `webscraper` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | Structured Firecrawl I/O; no reasoning. |
| `webmonitor` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | Repeated change-tracking runs; cost-sensitive. |
| `ha` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | HA MCP entity/device calls; structured. |
| `jira` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | JQL/transitions/worklogs via MCP; structured. |
| `stitch-mcp` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | MCP-driven Stitch design calls. |
| `graphify` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | Orchestrates AST + parallel extraction; code-only updates need no LLM (§10). |
| `graphify-extractor` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | Parallel per-chunk LLM extraction worker (§10). |
| `git` | `opencode-go/minimax-m3` · off | `kilo/minimax/minimax-m3` · off | Deterministic git hygiene within tight rails (§9). |
| `plan` (built-in) | inherits default | inherits default | Read-only planner. |

**openai spread:** `skill-smith` on `gpt-5.6-terra`; `webresearcher`
on `gpt-5.6-luna`. Upgrades: `gpt-5.6-sol`/`gpt-5.5` (frontier); budget:
`gpt-5.4-mini`. **GLM latency (work):** ~10s TTFT; if `architect`/`autopilot`
drag, fall back to `kilo/deepseek/deepseek-v4-pro`.

The full table + justifications are duplicated into `docs/model-selection.md`
(rewritten from the colleague's Kilo-only version, using its methodology).

---

## 4. Superpowers & skills — submodule-vendored

Switch from the live config's git-plugin-URL to the colleague's submodule-
vendored approach. Initialize the vendored `.gitmodules`: `superpowers`,
`anthropics-skills`, `cloudflare-skills`, `stitch-skills`, `awesome-agent-skills`,
`jenkins-cli`. Recreate `plugins/superpowers.js` symlink + the `skills/*`
discovery symlinks (deliberately not created during the raw vendor copy).

Vendor the **graphify** skill (`SKILL.md` + `references/`) into `skill/`; the
`graphifyy` CLI self-installs via `uv tool install` inside the skill, so no
`node_modules`/binary bloat is committed.

**Per-agent skill whitelists** (token optimization) retained: `permission.skill:
{"*": "deny", "<skill>": "allow"}` — only `deny` saves tokens (hides the skill
from `<available_skills>`). `scripts/check-skill-whitelists.sh` verifies every
whitelisted name resolves on disk. The `graphify` skill is whitelisted only to
`graphify` + orchestrators (`architect`/`autopilot`/`general`).

---

## 5. context7 — CLI approach

Keep the current-live **`npx ctx7@latest` CLI block in `AGENTS.md`**. Do NOT
adopt the colleague's MCP-remote-server + `secrets/context7.key` — dropped as
redundant. Consequence: **no** context7 MCP server, **no** context7 secret.

The `ctx7` CLI needs a bash allow or every lookup prompts:
`bash: { "npx ctx7*": "allow", "ctx7*": "allow" }`. Agents expected to self-serve
docs need `bash: true`; pure-MCP/no-bash operators delegate instead. Documented
in the `AGENTS.md` context7 block.

---

## 6. Plugins

`opencode.jsonc` `plugin` array:

| Plugin | Choice / notes |
|---|---|
| `superpowers` | submodule-vendored (§4) |
| `opencode-anthropic-oauth` | keep (in live config today) |
| `opencode-mnemosyne` | **add** — persistent cross-session memory (SQLite + FTS5 + sqlite-vec) + `docs/memory-rules.md` routing rules (adapted, reviewed for our roster) |
| `opencode-caffeinate` | **k-dylan fork** — adds `-s` system-sleep prevention + multi-agent event counting (relevant with background-agents) |
| `opencode-background-agents` | **kdcokenny original** — strict read-only always; `delegate` restricted to read-only subagents, write/bash delegation must use the native `task` tool (background sessions run outside the undo/branch tree) |
| `opencode-dynamic-context-pruning` (`@tarquinen/opencode-dcp`) | **primary** context management; native `compaction` kept as a fallback floor. `dcp.jsonc` gets explicit per-provider context-limit tuning (opencode-go, kilo, openai, anthropic) |
| `claude-bash-approve` (`mariusvniekerk/…`) | **add for testing** — deterministic Go bash-approval runtime (§8) |

---

## 7. Memory

Add `opencode-mnemosyne` + `docs/memory-rules.md`. Store/recall routing rules
adapted from the colleague's version and reviewed against the final roster.

---

## 8. Permissions & autonomy

Goal: wide permissions for autonomous / low-user-effort work, with a deterministic
safety floor that does **not** depend on the historically-flaky `permission.ask`
plugin hook.

### Bash approval — broad native baseline; `claude-bash-approve` deferred

- **Native baseline (intentional):** `opencode.jsonc` `bash` default is
  **`allow`**, matching the user's broad-autonomy preference.
- **Native hard `deny` backstop** for catastrophic commands (`rm -rf`, `dd`,
  `mkfs`, `reboot`/`shutdown`/`poweroff`, `git push --force`, `terraform
  destroy`) — explicit denies remain the safety baseline.
- **`claude-bash-approve`:** isolated classifier tests passed, but active
  deployment is deferred. If later activated, install with
  `python3 install.py install --target opencode --scope both`; it is not part
  of the current permission decision.
- **`AGENTS.md` hard-rules** remain the behavioral net — immune to the
  inline-env-var-prefix pattern bypass (issue #16075) that can defeat native
  bash patterns.

**Test/verification items (because the `permission.ask` hook has a broken history
— issues #7006/#9229/#22311/#19927):**
1. Does the hook intercept on 1.18.2? (safe cmd → no prompt; dangerous → block.)
2. Precedence: how does a plugin decision compose with a per-agent native
   `allow`? (Does agent-allow bypass the plugin, or can the plugin's `deny`
   still override?) — directly affects §9.
3. Confirm `categories.yaml` location and that our tuning takes effect.

The current native baseline is broad `bash: allow` plus explicit denies; no
plugin fallback decision is needed while `claude-bash-approve` remains deferred.

### Hands-off runs — native `--auto`

`opencode run --auto` (confirmed on 1.18.2) auto-approves everything not
explicitly denied; explicit denies + hard-rules still hold. This is the
mechanism for genuinely hands-off sessions (pairs with `autopilot` +
`opencode-background-agents`), rather than a permission plugin.

### Other permission rules (global + carried into any project config)

- **Global config always readable:** `read: allow` + `external_directory: allow`
  for `~/.config/opencode/**` from any session/agent.
- **`.tmp` enforcement:** agents use `<project>/.tmp`, not system `/tmp`
  (harness's own external-scratch dir is a separate, explicit exception).
- **Task delegation:** every agent carries an explicit `task` rule
  (`{"*": "allow", "autopilot": "deny"}` for general agents) because
  `deriveSubagentSessionPermission` injects `task: {"*": "deny"}` onto a subagent
  unless its own ruleset already declares `task`. Scoped exceptions: `graphify`
  (`{"*": "deny", "graphify-extractor": "allow"}`), `graphify-extractor` and
  `git` (`{"*": "deny"}`).

---

## 9. `git` agent — autonomous

Loosen `agents/git.md` from "everything `ask`" to autonomous, keeping destructive
/ history-rewriting ops guarded.

**`allow`** (was `ask`): `git add`, `git commit`, `git restore --staged`,
`git restore`, `git switch`, `git checkout <branch>`, `git stash push/pop/apply`,
`git tag`, `git merge`; **add** `git pull`, `git fetch`. Plus existing read ops
(`status`/`diff`/`log`/`branch`/`show`/`ls-files`/`stash list`).

**`ask`:** `git push*` (default — **per-repo overridable**, see below),
`git reset*` (non-hard), `git rebase*`, `git push --force-with-lease*`,
`git checkout -- <file>` (discard working changes).

**`deny`:** `git push --force*` / `-f`, `git reset --hard*`, `git clean*`,
`git rebase -i*`, `git filter-branch*`, `git checkout .` (discard-all).

**Other:** `steps: 30 → 40`; `edit: deny`, `task: {"*": "deny"}`, `skill: allow`
unchanged; model `…/minimax-m3`.

**Per-repo push override:** a project may promote `git push` for that repo via
its local `.opencode`/`opencode.json`:
```json
{ "agent": { "git": { "permission": { "bash": { "git push": "allow", "git push origin*": "allow" } } } } }
```
documented in that repo's `AGENTS.md`. Force-push stays `deny` regardless.

Pattern ordering matters (last match wins): `"*"` first, general allows next,
specific denies last. Note the env-var-prefix bypass (#16075) — hard-rules +
`claude-bash-approve` are the real backstop, not these patterns alone.

---

## 10. graphify — orchestrator + parallel flash extraction

graphify builds a persistent per-project knowledge graph (`graphify-out/`) for
repo-structure Q&A. Two new agents, both `deepseek-v4-flash`:

**`graphify` (orchestrator)** — owns the `graphify` skill; runs
detect → AST (Part A, deterministic, no LLM) → dispatches N parallel extraction
workers (Part B) → merge/cluster (Part C) → serves `graphify query`.
- `bash: true`, `read: true`, `edit: deny` (all writes land under `graphify-out/`
  via the CLI).
- `task: {"*": "deny", "graphify-extractor": "allow"}` — can spawn only
  extraction workers, and still works when `graphify` is itself dispatched as a
  subagent (the `canTask` mechanism).

**`graphify-extractor` (parallel worker, new, hidden)** — one dispatched per
20–25-file chunk, all in one message = parallel LLM extraction.
- Reads its chunk, extracts entities/relationships per
  `references/extraction-spec.md`, **writes** `graphify-out/.graphify_chunk_NN.json`.
- **Must be write-capable** (`read: true` + `write: true`): the chunk file on
  disk is the success signal; a read-only/Explore-type worker silently produces
  nothing and breaks the run.
- Its broad write/Bash permission is intentional worker-execution capability,
  not a safety defect; it remains a non-delegating, hidden leaf agent.
- `skill: {"*": "deny"}`, `task: {"*": "deny"}` — cheapest possible leaf worker.

**Automatic maintenance (per-project, three layers):**
1. **Post-commit hook** (`graphify hook install`) — primary auto path: rebuilds
   the graph on every commit for changed **code** files, no LLM, no daemon.
2. **`@graphify` agent** — the LLM-requiring paths the hook can't do: initial
   build and doc/semantic `--update`, plus serving queries.
3. **Optional `--watch`** — a background watcher (via tmux-mcp) for heavy
   agent-wave sessions.

**Per-project opt-in + documentation:** graphify is **not** global-on. It's for
"bigger projects," decided **with the user per project**. On opt-in: `@graphify`
builds the initial graph, installs the post-commit hook, and the decision is
recorded in that project's `AGENTS.md` (graphify enabled, `graphify-out/`
location, routing rule "repo-structure questions → `@graphify`; don't
broad-read", when a manual `--update` is needed). The **global** config ships only
the capability (agent + skill); each project's `AGENTS.md` is where opt-in lives.

---

## 11. Web-agent family — differentiation

Four distinct tools; sharpen descriptions + add `AGENTS.md` routing so
orchestrators/autopilot don't misroute:

| Agent | Job | Tools | Model | Cost |
|---|---|---|---|---|
| `web-fast-context` | Quick single-fact lookup | raw `websearch`+`webfetch` | deepseek-v4-flash | tokens only |
| `webresearcher` | Multi-source research + synthesis | Firecrawl MCP suite | gpt-5.6-luna | Firecrawl credits + frontier |
| `webscraper` | Extract a **known** URL (page/crawl/JS) | Firecrawl scrape/map/crawl/interact | deepseek-v4-flash | credits |
| `webmonitor` | Page-change tracking | Firecrawl | deepseek-v4-flash | credits |

**Description edits:**
- `web-fast-context`: "Fast single-lookup web/official-docs facts via raw
  websearch/webfetch — versions, API details, provider/tool references. No
  Firecrawl, no scraping/crawling. For multi-source research & synthesis use
  @webresearcher; to extract a known URL use @webscraper."
- `webresearcher` (add): "If the caller only needs a quick single fact or
  version/flag lookup (not multi-source search + synthesis), tell them to use
  @web-fast-context — it's faster and spends no Firecrawl credits."

---

## 12. autopilot

Adopt the base opus→sonnet primary orchestrator **globally only** (no
kube1-scoped variant): `mode: primary` (never dispatchable as a subagent),
`bash: false`, `edit` denied except its own `.agents/superpowers/**` audit trail,
drives the `autonomous-execution` skill (UNDERSTAND → DESIGN → PLAN → EXECUTE via
subagents → VERIFY via independent review → REPORT), with hard-stops (reboot/
shutdown, `rm -rf`, force-push to main, `terraform destroy`/prod `kubectl
delete`, DB `DROP`/`TRUNCATE`, financial ops). Model: `…/claude-sonnet-4-6` ·
medium (personal) / `kilo/z-ai/glm-5.1` (work). Not dispatchable: `mode: primary`
+ `task: {autopilot: deny}` on every delegating agent.

---

## 13. MCP servers

From base, reconciled: keep `github`, `playwright`, `chrome-devtools`,
`firecrawl`, `homeassistant`, plus the live config's `tmux-mcp`. **Drop**
`context7` MCP (CLI instead, §5). Per-agent tool enables/disables as in the base
(`playwright_*`/`chrome-devtools_*`/`firecrawl_*`/`homeassistant_*` globally
disabled, re-enabled per owning agent). `stitch`/`jira`/`dart` MCP per roster
need. Exact enable/disable matrix finalized in the implementation plan.

---

## 14. Dotfiles wiring — deferred

Mechanism settled in principle: `ln -s ~/.dotfiles/opencode/config
~/.config/opencode` (matches the nvim/tmux/ghostty/yabai pattern), with
`opencode.local.jsonc` + `secrets/` present-but-gitignored in the target. **Not
built now.** This work produces a complete, correct config tree under
`~/.dotfiles/opencode/` and leaves the live `~/.config/opencode` and
`bootstrap.sh` untouched. No `opencode.local.jsonc`, no secrets, no symlink, no
commit as part of implementation unless the user explicitly asks.

---

## 15. Open verification items (carry into the plan)

1. `claude-bash-approve` hook actually intercepts on 1.18.2; plugin-vs-agent-
   permission precedence (§8).
2. Inline env-var-prefix bypass (#16075) fixed in 1.18.2? (affects reliance on
   native bash patterns.)
3. `deriveSubagentSessionPermission` `canTask` behavior on 1.18.2 (task
   delegation §8).
4. Skill-whitelist `deny`-hides-tokens behavior still holds on 1.18.2.
5. Exact MCP enable/disable matrix (§13) and which agents get `bash: true` for
   ctx7 (§5).
