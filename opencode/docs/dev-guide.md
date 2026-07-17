# Dev Guide: Staged OpenCode Config

Reference for editing the staged configuration at
`~/.dotfiles/opencode/`. It is the future target for
`~/.config/opencode`, but is not deployed, symlinked, or live yet. Read this
before changing configuration, agents, skills, or scripts.

## Layout

```text
~/.dotfiles/opencode/
├── opencode.jsonc                   # Shared config: plugins, permissions, agents, MCP
├── opencode.local.*.example.json    # Per-machine model/provider templates
├── dcp.jsonc                        # Dynamic Context Pruning configuration
├── AGENTS.md                        # Staged global instructions
├── agents/                          # 24 custom agent definitions
├── docs/                            # Rules, plans, specs, and model selection
├── skill/graphify/                  # Vendored graphify skill and references
├── plugins/superpowers.js           # Symlink into the superpowers submodule
├── skills/                          # Discovery symlinks into skill submodules
├── superpowers/                     # Git submodule
├── anthropics-skills/               # Git submodule
├── cloudflare-skills/               # Git submodule
├── stitch-skills/                   # Git submodule
├── awesome-agent-skills/            # Git submodule
├── jenkins-cli/                     # Git submodule
└── secrets/                         # Gitignored machine-local secret files
```

The shared `opencode.jsonc` has no model, small-model, or machine-specific
provider configuration. Copy the appropriate example to the gitignored
`opencode.local.jsonc` and load it through `OPENCODE_CONFIG`. See
`docs/model-selection.md` for the four-provider model table and assignment
rationale.

## Agent Roster

The staged roster has 24 custom agents plus OpenCode's built-in read-only
`plan` agent. The five additions to the colleague baseline are `git`,
`web-fast-context`, `graphify`, `graphify-extractor`, and `reviewer`.

`graphify` owns graph construction and queries. It may dispatch only the hidden
`graphify-extractor` worker, which writes extraction chunks beneath a project's
`.agents/graphify-out/`. The capability is opt-in per project; see
`docs/graphify-project-optin.md`.

### Visibility

Ten generalist agents stay visible in the UI: `general`, `autopilot`,
`architect`, `coder`, `debugger`, `devops`, `frontend`, `writer`,
`skill-smith`, and `reviewer`. Each carries a skill-first, delegate-
deliberately directive: check `<available_skills>` before acting, follow
brainstorming → writing-plans → implementation → verification-before-
completion for non-trivial work, and delegate independently-scoped work to
the specialist that owns it rather than doing it directly.

The remaining fourteen agents carry `hidden: true` and are reachable only via
delegation (`@name` or the `task` tool), not from the agent picker: `git`,
`graphify`, `graphify-extractor`, `web-fast-context`, `webdebugger`,
`webscraper`, `webresearcher`, `webmonitor`, `cloudflare`, `ha`, `jenkins`,
`jira`, `stitch`, `stitch-mcp`. These stay narrowly scoped to their owning
domain and are not given the generalist skill-first directive.

Use `permission:` in agent frontmatter and `opencode.jsonc` for all access
rules. The deprecated access-map configuration format is not used.

## Documentation Lookups

Use the ctx7 CLI for current library, framework, SDK, API, CLI, and cloud
service documentation:

```bash
npx ctx7@latest library <name> "<full question>"
npx ctx7@latest docs <library-id> "<full question>"
```

The shared bash permission allows `npx ctx7*` and `ctx7*`. Keep credentials out
of lookup queries.

## Plugins And Runtime Behavior

- `opencode-mem` provides persistent memory (local vector DB, auto-capture,
  and a `memory` tool) described in `docs/memory-rules.md`. Its own config
  lives at `~/.config/opencode/opencode-mem.jsonc` (gitignored, per-machine);
  copy `opencode-mem.personal.example.jsonc` or `opencode-mem.work.example.jsonc`
  to `opencode-mem.jsonc` and adjust.
- `opencode-caffeinate` keeps macOS awake while OpenCode sessions are active.
- `opencode-background-agents` uses the strict read-only implementation:
  background delegations cannot edit files or run bash. Reserve background
  delegation only for genuinely long-running asynchronous jobs (e.g. slow
  read-only research or analysis that would otherwise block the session).
  For everything else, including any work with side effects, default to
  standard native `task` delegation instead.
- `@tarquinen/opencode-dcp@latest` supplies Dynamic Context Pruning; its
  `dcp.jsonc` settings are the primary context-management policy, with native
  compaction retained as a fallback floor.
- `claude-bash-approve` (vendored as the `claude-bash-approve/` submodule) is
  the active bash approval gate. `permission.bash.*` is `"ask"` at the global
  level (and inherited by every agent that does not declare its own `bash`
  ruleset), so the classifier's `permission.asked` hook — not a broad native
  `allow` — makes the real allow/deny/ask decision for anything not already
  covered by an explicit pattern. Explicit native `allow` entries (read-only
  commands, `ctx7`) and hard `deny` entries (`rm -rf`, `terraform destroy`,
  etc.) still take precedence over the plugin, since the plugin only fires
  when the native ruleset would otherwise prompt.
  Run `scripts/install-bash-approve.sh` once per machine after cloning and
  initializing submodules — it builds/installs the Go runtime to
  `~/.local/share/claude-bash-approve` and renders the gitignored
  `plugins/bash-approve.ts` with that machine's hook path. Restart OpenCode
  afterward; config loads only at startup.
- No agent `.md` frontmatter may declare a flat `bash: allow` (or any other
  flat `allow` for a permission key with global hard denies). A flat value
  becomes a single `{pattern: "*", action: allow}` rule appended after the
  global ruleset, which wins over every hard deny for that agent regardless
  of specificity — verified empirically against OpenCode 1.18.2's `evaluate()`
  (`findLast` over the concatenated array). Agents needing bash access rely on
  the inherited global ruleset, or declare their own `bash` object (not a
  flat string) with an explicit `"*"` action plus overrides, as `debugger`,
  `devops`, `jenkins`, `git`, `autopilot`, and `reviewer` do.

## Validation

There is no build system. For configuration changes, run:

```bash
python3 -c "import json; json.load(open('opencode.jsonc')); print('valid')"
bash scripts/check-skill-whitelists.sh
```

Verify Markdown frontmatter and permission changes against the current
OpenCode schema when their shape is uncertain. Do not deploy this staged tree,
modify `~/.config/opencode`, or change `bootstrap.sh` as part of documentation
or configuration maintenance unless that work is explicitly requested.
