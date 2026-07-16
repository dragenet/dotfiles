# Dev Guide: Staged OpenCode Config

Reference for editing the staged configuration at
`~/.dotfiles/opencode/config/`. It is the future target for
`~/.config/opencode`, but is not deployed, symlinked, or live yet. Read this
before changing configuration, agents, skills, or scripts.

## Layout

```text
~/.dotfiles/opencode/config/
├── opencode.json                    # Shared config: plugins, permissions, agents, MCP
├── opencode.local.*.example.json    # Per-machine model/provider templates
├── dcp.jsonc                        # Dynamic Context Pruning configuration
├── AGENTS.md                        # Staged global instructions
├── agents/                          # 23 custom agent definitions
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

The shared `opencode.json` has no model, small-model, or machine-specific
provider configuration. Copy the appropriate example to the gitignored
`opencode.local.json` and load it through `OPENCODE_CONFIG`. See
`docs/model-selection.md` for the four-provider model table and assignment
rationale.

## Agent Roster

The staged roster has 23 custom agents plus OpenCode's built-in read-only
`plan` agent. The four additions to the colleague baseline are `git`,
`web-fast-context`, `graphify`, and `graphify-extractor`.

`graphify` owns graph construction and queries. It may dispatch only the hidden
`graphify-extractor` worker, which writes extraction chunks beneath a project's
`graphify-out/`. The capability is opt-in per project; see
`docs/graphify-project-optin.md`.

Use `permission:` in agent frontmatter and `opencode.json` for all access
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

- `opencode-mnemosyne` provides persistent memory routing described in
  `docs/memory-rules.md`.
- `opencode-caffeinate` keeps macOS awake while OpenCode sessions are active.
- `opencode-background-agents` uses the strict read-only implementation:
  background delegations cannot edit files or run bash. Use native `task`
  delegation for work with side effects.
- `@tarquinen/opencode-dcp@latest` supplies Dynamic Context Pruning; its
  `dcp.jsonc` settings are the primary context-management policy, with native
  compaction retained as a fallback floor.
- `claude-bash-approve` has been verified only in isolated classifier tests.
  Its active deployment remains deferred; the native bash `ask` default and
  explicit catastrophic-command denies remain the safety floor.

## Validation

There is no build system. For configuration changes, run:

```bash
python3 -c "import json; json.load(open('opencode.json')); print('valid')"
bash scripts/check-skill-whitelists.sh
```

Verify Markdown frontmatter and permission changes against the current
OpenCode schema when their shape is uncertain. Do not deploy this staged tree,
modify `~/.config/opencode`, or change `bootstrap.sh` as part of documentation
or configuration maintenance unless that work is explicitly requested.
