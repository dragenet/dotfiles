# Handoff: OpenCode global config redesign

> **Current state notice (2026-07-16):** The redesign is now implemented in
> staged `~/.dotfiles/opencode/`. This document is historical discovery
> context only. Do not restart brainstorming, re-discover the recorded findings,
> or follow the old "nothing done" checklist below; use the current design and
> implementation-plan documents for the staged configuration's state.

Paste this whole file as the opening prompt for the next session (any agent/CLI
that reads it as context). It is self-contained: goal, current state, findings,
constraints, and open questions. The previous session used the
`superpowers:brainstorming` skill and got as far as one dismissed clarifying
question — resume from there, don't restart the discovery work described below.

---

## Mission

Rebuild `~/.config/opencode` (currently a live, organically-grown, undocumented
config) into a clean, portable, cost/performance-optimized setup, using
`https://github.com/jabbas/opencode-config` (a friend's config) as the
architectural base — **without** losing the repo-specific work already done in
`infra-flux` (kube1 cluster repo), and **without** blindly copying integrations
that don't apply to this user.

Continue with the `superpowers:brainstorming` skill (already in progress — see
"Where brainstorming left off" below), through to `writing-plans` and
implementation. Do not skip straight to implementation.

---

## Current state (as of 2026-07-16, end of previous session)

### What has been done

1. **Discovery only** on `~/.config/opencode` (live global config) and the
   `infra-flux` repo (`~/Projects/fux-infra/infra-flux`) — documented in full
   below. No changes were made to either.
2. Cloned `jabbas/opencode-config` (commit `6a85a4b3f`) to a scratch dir and
   read every file.
3. **Vendored** (raw file copy, no git history, no submodules initialized) the
   friend's repo structure into `~/.dotfiles/opencode/`, replacing what was
   there before (`opencode.jsonc`, `agents/git.md` — see below, these are now
   `git status` deletions, recoverable via `git checkout -- opencode/` in the
   `~/.dotfiles` repo if needed). See `~/.dotfiles/opencode/VENDORED_FROM.md`
   for exact provenance.
4. **Nothing is committed.** `git -C ~/.dotfiles status` currently shows the
   opencode/ changes as staged-worthy but uncommitted, plus unrelated
   pre-existing nvim changes (`nvim/lazy-lock.json`,
   `nvim/lua/plugins/comment.lua`, new `nvim/lua/plugins/sops.lua`) that are
   NOT part of this work — don't touch or commit those as part of this task
   unless asked.
5. **`~/.config/opencode` (the live config) was NOT touched.** It is still the
   old setup and still functions normally. `~/.dotfiles/opencode/` is currently
   inert — nothing symlinks to it, `bootstrap.sh` has no opencode step.

### What is explicitly NOT done yet

- No trimming of the friend's agent roster (jira/jenkins/home-assistant/
  cloudflare/stitch/firecrawl-web-agents are all still present, vendored as-is)
- No model/provider mapping for **our** providers (opencode-go/kilo gateway,
  openai, anthropic) — the friend's `docs/model-selection.md` is Kilo-only and
  explicitly excludes frontier models (NDA constraint that doesn't apply to us)
- No reconciliation with the currently-live `~/.config/opencode` (its
  `tmux-mcp` MCP + permissions, `opencode-anthropic-oauth` plugin, `context7`
  ctx7-CLI-based AGENTS.md block, `kilo` provider header config — see below)
- No reconciliation with `infra-flux`'s local `.opencode/agents/*` and
  `.opencode/skills/kube1-*` (9 local subagents, 4 local skills — see below)
- `web-fast-context` agent has NOT been migrated from `infra-flux/.opencode/agents/`
  to global agents yet — still pending from before this redesign started
- `.gitmodules` submodules not initialized, not pruned
- `plugins/` and `skills/` symlink dirs (present in friend's repo, pointing
  into submodules) were deliberately **not** recreated in the vendored copy —
  they'd be broken without initialized submodules
- No `opencode.local.jsonc` created (gitignored by design — machine-specific)
- No secrets set up
- Not wired into `~/.dotfiles/bootstrap.sh` or symlinked into `~/.config/opencode`
- Not committed to the `dotfiles` git repo

### Where brainstorming left off

The previous session invoked `superpowers:brainstorming` and asked exactly one
clarifying question, which the user **dismissed** (declined to answer inline —
not "no", just deferred). It must be asked again, first, in the next session:

> **Which of the friend's specialist agents/integrations are actually relevant
> to you, so we don't port dead weight?**
>
> - **Core dev roster only (was marked Recommended):** `general`/`coder`/
>   `architect`/`debugger`/`devops`/`writer`/`skill-smith` + `autopilot`. Drop
>   `jira`, `home-assistant` (`ha`), `stitch`/`stitch-mcp`, `cloudflare`,
>   `jenkins`, and the Firecrawl web agents (`webscraper`/`webresearcher`/
>   `webmonitor`) entirely.
> - **Core dev + web research/scrape:** above, plus `webresearcher`/
>   `webscraper`/`webmonitor` (Firecrawl-backed) if actually used for docs
>   research.
> - **Core dev + browser testing:** above, plus `webdebugger` (Playwright /
>   chrome-devtools MCP) if doing frontend/UI verification work.
> - **Home Assistant:** user actually uses HA and wants the `ha` MCP agent kept.
> - **Jira / Jenkins / Cloudflare / Stitch:** user uses one or more and wants
>   it kept (ask which).

Resolve this before writing the design doc — it determines the whole agent
roster, which MCP servers to configure, which submodules to init, and which
secrets to set up.

---

## Full findings from discovery (don't re-discover, just verify if stale)

### 1. `~/.dotfiles` / `~/.config/opencode` relationship

- `~/.config/opencode` is a **real directory, not a symlink**. It is currently
  *ahead* of (diverged from) `~/.dotfiles/opencode`: different
  `opencode.jsonc` content, different `agents/git.md`, plus files
  `~/.dotfiles/opencode` never had at all (`AGENTS.md`, `.gitignore`,
  `package.json`, `package-lock.json`, `node_modules/`, `agents/` had only
  `git.md`).
- `~/.dotfiles/bootstrap.sh` has **no opencode section at all** — unlike nvim/
  tmux/ghostty/yabai, which are all symlinked from `~/.dotfiles/<tool>` into
  place. There is no existing automation to update or extend for opencode.
- `~/.dotfiles` README documents the symlink pattern for the other 4 tools;
  opencode should probably be added there too once the design is finalized —
  decide: symlink the whole `~/.dotfiles/opencode/` dir to `~/.config/opencode`
  (matches existing dotfiles pattern, requires `opencode.local.jsonc` +
  `secrets/` to still work when gitignored-but-present in the *target*, not the
  source — needs testing) vs. some other mechanism. The friend's own repo IS
  `~/.config/opencode` directly (cloned there, no separate dotfiles indirection)
  — using it as a dotfiles subdirectory that gets symlinked is a deliberate
  deviation for this user's existing multi-tool dotfiles convention; confirm
  this is still wanted.
- Currently live `~/.dotfiles` git remote: `git@github.com:dragenet/dotfiles.git`.

### 2. Currently-live `~/.config/opencode` (the real one, still active)

`~/.config/opencode/opencode.jsonc`:
```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "opencode-anthropic-oauth",
    "superpowers@git+https://github.com/obra/superpowers.git"
  ],
  "permission": {
    "webfetch": "allow", "websearch": "allow",
    "tmux-mcp_list-sessions": "allow", "tmux-mcp_find-session": "allow",
    "tmux-mcp_list-windows": "allow", "tmux-mcp_list-panes": "allow",
    "tmux-mcp_capture-pane": "allow", "tmux-mcp_create-session": "allow",
    "tmux-mcp_execute-command": "ask", "tmux-mcp_get-command-result": "allow",
    "tmux-mcp_create-window": "ask", "tmux-mcp_split-pane": "ask",
    "tmux-mcp_kill-session": "ask", "tmux-mcp_kill-window": "ask",
    "tmux-mcp_kill-pane": "ask"
  },
  "mcp": { "tmux-mcp": { "type": "local", "command": ["npx", "-y", "tmux-mcp"], "enabled": true } },
  "provider": { "kilo": { "options": { "headers": { "X-KiloCode-OrganizationId": "3a7df54f-e84d-46f9-8a71-8216ebc1fa58" } } } },
  "lsp": true
}
```
- `~/.config/opencode/AGENTS.md` is currently just the `context7`/`ctx7` CLI
  usage block (`npx ctx7@latest library/docs ...`) — **not** the MCP-based
  context7 the friend's repo uses (`mcp.context7.com/mcp` remote server +
  `secrets/context7.key`). Decide which context7 integration style to keep —
  they are mutually redundant, pick one.
- `~/.config/opencode/agents/git.md` — only existing custom global subagent
  today. Fairly locked-down git-hygiene subagent (no push, no force, no
  rebase/hard-reset/clean without explicit ask, `task: deny`, `skill: allow`,
  `model: kilo/minimax/minimax-m3`, `steps: 30`). Full content was read; reuse/
  adapt rather than re-invent — it already encodes good safety defaults for a
  `git` subagent role.
- `~/.local/share/opencode/auth.json` holds provider credentials incl. a
  `kilocode` key (referenced in the friend's own `docs/model-selection.md`
  methodology, which we should imitate for methodology but not content since
  they're Kilo-only/NDA-constrained and we are not).
- The superpowers plugin is loaded straight from git
  (`superpowers@git+https://github.com/obra/superpowers.git`), cached at
  `~/.cache/opencode/packages/superpowers@git+https:/github.com/obra/superpowers.git/node_modules/superpowers/`.
  It **auto-registers** its own `skills/` dir into `config.skills.paths` at
  runtime (no manual symlink needed — this is a real difference from the
  friend's repo, which vendors superpowers as a git submodule + symlinks
  `plugins/superpowers.js` + `skills/superpowers`). Decide: keep the
  git-plugin-URL approach (simpler, always latest, what we have today) or
  switch to the friend's submodule-vendored approach (pinned version,
  offline-safe, consistent with vendoring the rest of their skill sets). The
  git-plugin approach requires no `.gitmodules`/symlink maintenance and is
  probably preferable unless we specifically want a pinned superpowers version.
- Global superpowers skills available today (13, all from the plugin, already
  confirmed working): `brainstorming`, `dispatching-parallel-agents`,
  `executing-plans`, `finishing-a-development-branch`, `receiving-code-review`,
  `requesting-code-review`, `subagent-driven-development`,
  `systematic-debugging`, `test-driven-development`, `using-git-worktrees`,
  `verification-before-completion`, `writing-plans`, `writing-skills`, plus
  `using-superpowers` (bootstrap skill, auto-injected into first user message
  by the plugin's `experimental.chat.messages.transform` hook — this is how
  "you have superpowers" framing gets into every session without a system
  message).

### 3. `infra-flux` repo (`~/Projects/fux-infra/infra-flux`) — local, repo-specific

This repo's local OpenCode config must be preserved/reconciled, not discarded:

- `opencode.jsonc`: `default_agent: build`, model `openai/gpt-5.4-mini-fast`,
  `small_model: opencode-go/minimax-m3`, `skills.paths: [".opencode/skills"]`,
  fairly cautious permissions (`edit: ask`, long `bash` allow/ask/deny list,
  `task: {"*":"ask"}`, `external_directory` allow only for one specific path).
  **This was mid-refactor from the original user request** (wide permissions
  for autonomous work, always-allow reading global config, `.tmp` enforcement)
  — that refactor was paused in favor of this bigger global redesign. Resume it
  as part of (or right after) the global redesign, applying the same
  philosophy consistently across global + local configs.
- `AGENTS.md`: orchestrator contract — top-level session delegates by default,
  graphify-first repo discovery, subagent roster table, parallelization rules,
  ADR/report/doc-writer routing, safety notes (ask before destructive/live-
  cluster/provider-costing/secret-touching/history-rewriting commands).
- `.opencode/skills/`: `graphify` (vendored tool skill, npm-based, has its own
  `node_modules/` — huge, not skill content) + **4 repo-specific skills**:
  `kube1-workflow`, `kube1-architecture`, `kube1-orchestration`,
  `kube1-validation`. Full content was read. `kube1-orchestration` in
  particular **duplicates generic superpowers process guidance**
  (`dispatching-parallel-agents`, `subagent-driven-development` mechanics
  reinvented in kube1-specific prose) — flagged for trimming to just the
  kube1-specific routing table/safety/ADR-trigger rules, with explicit
  pointers to the superpowers skills for the generic mechanics instead of
  restating them. This trimming was identified but not yet done.
- `.opencode/agents/`: **9 local subagents**, full content read:
  `task-planner`, `web-fast-context`, `ansible-implementor`, `k8s-implementor`,
  `ansible-reviewer`, `k8s-reviewer`, `docs-writer`, `adr-writer`,
  `report-writer`. All are kube1-domain-specific **except `web-fast-context`**,
  which is a fully generic web-only docs/facts agent (no repo awareness,
  `read/edit/glob/grep/bash/task: deny`, only `webfetch`/`websearch` allowed,
  `hidden: true`, `model: kilo/deepseek/deepseek-v4-flash`). **Confirmed
  candidate to migrate to global `agents/`** — it has zero kube1-specific
  content and duplicates exactly the kind of role the friend's repo has
  (`webresearcher`, though that one is Firecrawl-backed instead of raw
  websearch/webfetch — decide whether `web-fast-context`'s raw-webfetch
  approach or the friend's Firecrawl-MCP approach is preferred, or keep both
  as distinct tools: fast quick lookups vs. deep scraping).
- `docs/contributing/working-with-agents.md`: prose doc describing the same
  subagent roster/orchestration contract for human contributors. References
  `web-fast-context` as if local — needs updating once it moves global.
- `.superpowers/sdd/` at repo root is **leftover generated work-artifacts**
  (task briefs/reports/diffs from a previous subagent-driven-development run)
  — not skill/agent config, out of scope for this redesign, optionally worth
  gitignoring/cleaning separately.
- Every kube1 local subagent already includes `task: {"*": "deny", "web-fast-context": "allow"}`
  — i.e. they already anticipated the "explicit task allow needed for nested
  delegation" gotcha described below, at least partially (only for
  `web-fast-context`, not general re-delegation). Cross-check against the
  friend's blanket `task: {"*":"allow","autopilot":"deny"}` pattern when
  redesigning — decide whether kube1 subagents should get broader re-delegation
  rights (e.g. `ansible-implementor` calling `web-fast-context` AND being able
  to hand off further) or stay narrowly scoped as today.

### 4. `jabbas/opencode-config` architecture (the base to build on)

Full repo read (`opencode.json`, `AGENTS.md`, `docs/global-rules.md`,
`docs/memory-rules.md`, `docs/model-selection.md`, `docs/dev-guide.md`,
`skill/autonomous-execution/SKILL.md`, `agents/{default,autopilot,architect,
coder,devops}.md`, `scripts/check-skill-whitelists.sh`, `secrets/README.md`,
`.gitmodules`). Now vendored into `~/.dotfiles/opencode/` verbatim (see
`VENDORED_FROM.md`). Key patterns worth keeping:

1. **Shared base + local layer.** `opencode.json` (tracked, identical across
   machines, NO model/provider info) + gitignored `opencode.local.jsonc`
   (models, `provider` block, per-agent model overrides), deep-merged at
   runtime via `OPENCODE_CONFIG` env var (set via shell alias or direnv
   `.envrc`, both documented in their README). This is the mechanism to adopt
   for keeping the `kilo`/`opencode-go` provider header config and any
   API-key-bearing provider config out of the tracked/dotfiles-committed file.
2. **Per-agent skill whitelists for token optimization.**
   `agent.<name>.permission.skill: {"*": "deny", "<skill>": "allow", ...}`.
   Confirmed mechanism (their comment cites `skill/index.ts:314`,
   `permission/index.ts:86`): a `deny`'d skill is fully hidden from
   `<available_skills>` (saves context tokens), not just blocked at
   invocation-time — `allow`/`ask` both keep it visible at full token cost.
   `scripts/check-skill-whitelists.sh` verifies every whitelisted skill name
   actually resolves to an on-disk `SKILL.md` or known builtin, run after
   editing whitelists.
3. **The subagent-delegation gotcha.** Every agent definition carries an
   explicit `task: {"*": "allow", "<primary-orchestrator>": "deny"}`. Their
   `AGENTS.md` explains why: OpenCode's `deriveSubagentSessionPermission`
   (in `subagent-permissions.ts`) auto-injects `task: {"*": "deny"}` onto any
   agent **when it is running as a subagent**, UNLESS that agent's own
   permission ruleset already declares a `task` rule (`canTask`). So without
   an explicit `task` allow on every agent definition, a subagent can never
   delegate further, no matter what the top-level config says. **This needs
   verifying against our current OpenCode version** (behavior could differ)
   before relying on it, but treat it as true until disproven — it directly
   affects the earlier ask "wide permissions for ... subagent invocations".
4. **`autopilot` primary agent** — `mode: primary` (hidden from being
   dispatchable as a subagent), opus-tier model, `bash: false`, `edit: false`
   except its own `.agents/superpowers/**` audit trail, drives a custom
   `autonomous-execution` skill: 6-step loop (UNDERSTAND → DESIGN → PLAN →
   EXECUTE-via-subagents-only → VERIFY-via-independent-subagent-review →
   REPORT-in-its-own-voice), with exactly **two** hard-stop conditions
   (irreversible/dangerous op, or irreducible ambiguity) and an explicit
   "Hard Stops" table (reboot/shutdown, `rm -rf`, force-push to main,
   `terraform destroy`/prod `kubectl delete`, DB `DROP`/`TRUNCATE`, financial
   ops). This is close to a direct answer to the very first ask in this whole
   task ("wide permissions for autonomous/low-user-effort work") — evaluate
   adopting an `autopilot`-equivalent primary agent (possibly renamed) at the
   global level, and/or a similar pattern scoped into `infra-flux` for
   low-touch kube1 work (would need kube1-specific hard-stops merged in:
   `talosctl`, `hcloud`, `flux reconcile`, `sops`, live `kubectl`, per the
   existing `infra-flux/AGENTS.md` safety rules).
5. **`docs/model-selection.md` methodology** (in Polish; friend's, June 2026
   dated) — good structure to imitate: agent → real workload → benchmark
   sources (KiloBench/SWE-bench/Terminal-Bench/etc.) → model assignment →
   cost table → rejected alternatives. Content is Kilo-only and explicitly
   excludes frontier models for an NDA reason that doesn't apply to this user.
   **Must be redone from scratch** for our 3 providers: `opencode-go` (kilo
   gateway), `openai`, `anthropic` — mapping each agent's real workload
   (reasoning/planning vs. bulk code-writing vs. cheap MCP-operator calls) to
   a cost-appropriate model per provider, analogous to how `infra-flux`'s
   existing kube1 agents already vary model per role (e.g. `task-planner` on
   `anthropic/claude-opus-4-8`, reviewers on `openai/gpt-5.5`, implementors on
   `kilo/deepseek/deepseek-v4-pro`, `web-fast-context` on
   `kilo/deepseek/deepseek-v4-flash`) — that existing kube1 pattern is a good
   starting point/precedent for the new global model-selection doc.
6. Other adoptable pieces: `docs/global-rules.md` (filesystem-path-safety +
   web-content delegation rules — the web-content-delegation part only applies
   if Firecrawl web agents are kept, see open question), `docs/memory-rules.md`
   (routing rules for a memory MCP plugin, `opencode-mnemosyne` — **decide if
   we want persistent cross-session memory at all**; not currently used in
   either of our configs), `scripts/check-skill-whitelists.sh` (reusable
   as-is, generic), the `agents/*.md` frontmatter style (`tools:` map instead
   of `permission.edit`/`permission.bash` maps for simple agents — mixed style
   vs. our existing kube1 agents which use fuller `permission.*` maps; decide
   one consistent style or justify the difference by agent complexity).

### 5. Three additional plugins requested (new, researched but not installed)

The user wants these added to the new global `opencode.json` `plugin` array, on
top of the base derived from `jabbas/opencode-config`. Researched via web
search this session (not yet installed/configured anywhere) — package names,
behavior, and open decisions below.

1. **`opencode-caffeinate`** — prevents macOS sleep while any OpenCode session
   is active. `caffeinate -dim` (display/idle/disk sleep prevention) starts on
   `session.created`, stops when all sessions end. macOS-only (fine, this
   machine is macOS/darwin), requires Bun ≥ 1.0.0. Tracks sessions via PID
   files under `/tmp/opencode-caffeinate/` (plugin-internal runtime state, not
   agent-authored work product — treat as an explicit exception to the
   project-`.tmp` rule, same category as this harness's own external-scratch
   dir convention). Install: `"plugin": ["opencode-caffeinate"]`. Multiple
   maintainer forks exist (`nguyenphutrong/opencode-caffeinate` is the npm
   package of record; `k-dylan` fork adds `-s` system-sleep prevention and
   same-process multi-agent event counting for plugins that spawn multiple
   agents in one process — e.g. relevant if `opencode-background-agents` or
   any autopilot-style orchestrator is also adopted; there's also an
   alternative implementation `IgnisDa/opencode-wakelock`). **Decide**: which
   fork/package (`opencode-caffeinate` vs a fork with `-s` support), no other
   real trade-offs — this one is low-risk/low-decision, safe to just add.

2. **`opencode-background-agents`** — adds `delegate(prompt, agent)` /
   `delegation_read(id)` / `delegation_list()` (some forks also add
   `delegation_status()`, `delegation_peek()`, `delegation_steer()`,
   `delegation_stop()`) tools for **async, fire-and-forget background subagent
   delegation** distinct from the native `task` tool: the parent session keeps
   working, results persist to disk as markdown under
   `~/.local/share/opencode/delegations/<project>/` (survives context
   compaction/session restart/crash, unlike native `task` results which live
   only in-session), and a notification arrives on completion. Directly
   relevant to the "wide permissions for autonomous/low-effort work" goal —
   this is a genuine capability upgrade for that, not just a nice-to-have.
   **Important open decision**: forks differ on write-capability policy.
     - `kdcokenny/opencode-background-agents` (the original, and the
       `ocx add kdco/background-agents` / KDCO-registry version): **hard
       restricts** `delegate` to read-only subagents only (`edit=deny`,
       `write=deny`, `bash={"*":"deny"}`); write-capable agents must use the
       native `task` tool instead. Rationale: background sessions run outside
       OpenCode's undo/branching tree, so file/bash side effects there can't
       be reverted through the UI.
     - `AeonDave/opencode-background-agents` fork: **relaxes** this by
       default — write/bash-capable subagents CAN run as background
       delegations (logged warning), reversible only via
       `BACKGROUND_AGENTS_STRICT_READONLY=1` env var to restore the strict
       original behavior. Also adds steer/stop/peek/status tools for
       mid-flight control, per-task configurable timeout (default 15 min,
       `0` = unbounded).
     - Given the stated goal (wide autonomy, low user effort), the AeonDave
       fork's relaxed-by-default model with `BACKGROUND_AGENTS_STRICT_READONLY`
       available as an opt-in safety switch is probably the better fit than
       the strictly-read-only original — but this trades off against "changes
       made in background sessions aren't in the undo/branching tree" which
       matters for a repo like `infra-flux` where reviewable, revertable
       change history matters. **Decide**: which fork, and whether to set
       `BACKGROUND_AGENTS_STRICT_READONLY=1` (recommended default: unset/relaxed
       for the `general`/`coder`/`devops`-style agents doing exploratory work,
       but consider forcing strict mode specifically for any kube1/infra-flux
       write-capable delegation given live-cluster/secret-touching stakes
       already established in that repo's safety rules).
   Install (npm form): `"plugin": ["opencode-background-agents"]` or
   `"plugin": ["@aeondave/opencode-background-agents@latest"]` depending on
   fork chosen; OCX-registry form also available
   (`ocx add kdco/background-agents --from https://registry.kdco.dev`).

3. **`opencode-dynamic-context-pruning` (DCP)** — package
   `@tarquinen/opencode-dcp` (org: `Opencode-DCP`, also packaged for AUR).
   Adds a `compress` tool the model can invoke autonomously (or manually via
   `/dcp compress`) to replace stale/closed conversation spans with
   high-fidelity technical summaries — described by its own docs as "a much
   smarter version of OpenCode's compaction process" because it triggers on
   task-completion signals rather than only at a static context-size
   threshold, and can target specific messages instead of the whole session.
   Also auto-prunes duplicate tool calls (same tool+args, keep latest) and
   stale error-tool inputs (configurable turn window, default 4). Session
   history is never mutated — pruned content is replaced with placeholders
   only in what's sent to the LLM. Install:
   `opencode plugin @tarquinen/opencode-dcp@latest --global` (CLI helper,
   ends up in the global `plugin` array); config lives in a **separate** file
   `~/.config/opencode/dcp.jsonc` (or project-level `.opencode/dcp.jsonc`),
   not inside `opencode.json` itself. **Decide/reconcile**: both our current
   global intent and `infra-flux`'s `opencode.jsonc` already set native
   `"compaction": {"auto": true, "prune": true, ...}` — DCP explicitly
   positions itself as a smarter superset of that mechanism, so the design
   doc should decide whether native compaction settings stay as a fallback
   floor or whether DCP fully takes over context management (and if so, tune
   `dcp.jsonc`'s `compress.maxContextLimit`/`minContextLimit`, which support
   per-model overrides — worth setting explicitly for our 3 providers'
   context windows). Also note `experimental.allowSubAgents` (default
   `false`) — decide whether subagent sessions should get DCP pruning too,
   which interacts with the `opencode-background-agents` decision above since
   background delegations are themselves subagent sessions.

All three are additive/config-only (no code changes to `infra-flux` or
existing skills required), so they can be added to the new base
`opencode.json` at the same time as the rest of the redesign — fold them into
the design doc's "MCP/plugin list" section rather than treating them as a
separate follow-up.

---

## Original user requirements (from the start of this task, still valid)

These were the goals before the friend's-repo pivot; they still apply and
should be satisfied by whatever the final design is, at both global and
`infra-flux`-local config levels:

1. Refactor repo (`infra-flux`) subagents and skills to seamlessly integrate
   with the globally-installed superpowers, **without duplications**.
2. Wide permissions for autonomous / low-user-effort semi-autonomous work —
   especially read/write, bash commands, subagent invocations.
3. Always allow reading the global OpenCode config
   (`~/.config/opencode/**`) from any session/agent — needs both a `read`
   permission allow and (since it's outside a project's cwd) an
   `external_directory` allow entry, in both global and local configs.
4. Enforce agents always use `<project>/.tmp` instead of the system `/tmp`,
   except where the global `/tmp` is explicitly required (e.g. this very
   handoff's scratch clone used
   `/var/folders/.../T/opencode/...` per this harness's own external-scratch
   convention — that's a harness-level exception, not a project one; the
   `.tmp` rule is about agents' own scratch files inside a project repo).
5. Clean up duplication between `infra-flux` and global superpowers (partially
   scoped above — `kube1-orchestration` skill trimming, mostly).
6. Migrate `web-fast-context` from `infra-flux/.opencode/agents/` to the
   global `agents/` dir (scoped above, not yet executed).
7. (New, this session) Base the global config on `jabbas/opencode-config`,
   optimized for cost/performance/relevance given **exactly 3** available
   model providers: `opencode-go` (kilo gateway), `openai`, `anthropic`.
8. (New, this session) Add three additional plugins to the rebuilt global
   config: `opencode-caffeinate`, `opencode-background-agents`,
   `opencode-dynamic-context-pruning` — see "5. Three additional plugins
   requested" above for package names, fork choices, and open decisions
   (background-agents' read-only-vs-write-capable policy in particular
   interacts directly with requirement #2 above).

---

## Suggested next steps (order)

1. **Re-ask the dismissed clarifying question** (agent roster scope) before
   anything else — it gates almost every other decision (roster, MCP servers,
   submodules, secrets).
2. Ask/settle the other decisions flagged inline above as "decide" (context7
   integration style, superpowers plugin-vs-submodule, memory plugin
   yes/no, `autopilot`-equivalent yes/no + whether it also gets a kube1-scoped
   variant, `.dotfiles` symlink mechanism, agent-definition frontmatter style
   consistency, plus the three plugin decisions from section 5: caffeinate
   fork, background-agents fork + strict-readonly policy, DCP vs. native
   `compaction` settings and per-provider context-limit tuning).
3. Produce the model-selection mapping for `opencode-go`/`openai`/`anthropic`
   per agent, using the friend's methodology as a template but redone for our
   providers (their doc explicitly says redo this — do not port their table).
4. Write the design doc via `superpowers:brainstorming` →
   `.agents/superpowers/specs/YYYY-MM-DD-opencode-config-redesign-design.md`
   (inside `~/.dotfiles/opencode/`, matching the vendored doc convention),
   covering: final agent roster, permission model (including the
   `.tmp`-enforcement rule, global-config-always-readable rule, and the
   task-delegation-allow pattern), model/provider mapping, MCP server list AND
   plugin list (`opencode-caffeinate`, `opencode-background-agents`,
   `opencode-dynamic-context-pruning`, plus `opencode-anthropic-oauth` already
   in use), `infra-flux` reconciliation plan (skill trimming +
   `web-fast-context` migration + resuming the paused local `opencode.jsonc`
   permission refactor), and the `~/.dotfiles` wiring/bootstrap plan.
5. Get user approval on the design doc, then `superpowers:writing-plans` →
   implementation, likely via `superpowers:subagent-driven-development` given
   the number of independent file-level changes involved.
6. Only after implementation + verification: wire `~/.dotfiles/bootstrap.sh`,
   symlink/deploy to `~/.config/opencode`, initialize needed submodules, set up
   `opencode.local.jsonc` + `secrets/*`, and — only if the user explicitly asks
   — commit.

---

## Constraints/reminders carried over from the active skill set

- `superpowers:using-superpowers` bootstrap is active globally already (via
  the plugin) — don't re-invoke `using-superpowers` itself, and prefer
  invoking other superpowers skills by name over restating their content.
- This is squarely `brainstorming` territory ("let's build/redesign X") — do
  not jump to implementation before a user-approved design doc exists, even
  though a lot of groundwork/vendoring has already happened non-destructively.
- Nothing destructive has occurred: the live `~/.config/opencode` is untouched
  and working; the only changes are new/uncommitted files under
  `~/.dotfiles/opencode/` (easily revertible with
  `git -C ~/.dotfiles checkout -- opencode/` if needed, though that would also
  restore the two old stale files this session deleted).
