# OpenCode Configuration

Staged OpenCode configuration for a future deployment: the Superpowers plugin
system, skill repositories (git submodules), custom agents, MCP servers, and
memory. It is not the live `~/.config/opencode` configuration yet.

This config is designed to run **identically on multiple machines** (e.g. a private
and a work laptop). The shared base (`opencode.jsonc`, agents, skills, docs) is the
same everywhere; everything machine-specific lives in two gitignored files:
`opencode.local.jsonc` (models/providers) and `secrets/*` (keys/URLs).

---

## How it works: shared base + local layer

| File | Tracked? | Same on every machine? | Holds |
|------|----------|------------------------|-------|
| `opencode.jsonc` | yes | **yes (identical)** | agents, MCP servers, skills, permissions, tool gating |
| `opencode.local.jsonc` | no (gitignored) | no | `model`, `small_model`, `provider` block, per-agent model overrides |
| `secrets/*` | no (gitignored) | no | API keys and infra URLs (`{file:secrets/...}`) |
| `.envrc` | no (gitignored) | no | optional direnv loader for `OPENCODE_CONFIG` |

At runtime OpenCode loads `opencode.jsonc`, then deep-merges `opencode.local.jsonc`
on top (via the `OPENCODE_CONFIG` env var). The local layer wins per-key, so it can
set models/providers without touching the shared base.

`{file:secrets/...}` references resolve **relative to the config directory**, so the
same `opencode.jsonc` automatically reads each machine's own `secrets/`.

---

## Models

The shared configuration is model-agnostic. Model and provider choices belong in
the gitignored local layer: personal machines use `opencode-go`, `anthropic`, and
`openai`; work machines use `kilo` as the NDA-safe default. Work-machine
`anthropic` and `openai` access is configured only for explicit, non-sensitive
opt-in use. No Qwen models are used.

The tracked templates are `opencode.local.personal.example.jsonc` and
`opencode.local.work.example.jsonc`; copy the applicable one to
`opencode.local.jsonc`. The exact per-agent assignments, reasoning variants, and
selection rationale are in `docs/model-selection.md`.

---

## Setup on a new machine (future procedure after deployment)

Deployment remains deferred. When this staged configuration is approved for
deployment, install it from this dotfiles repository rather than cloning into
`~/.config`:

```bash
git clone <repo-url> ~/.dotfiles
git -C ~/.dotfiles submodule update --init --recursive
mkdir -p ~/.config

# Check whether the live config already exists or is already a symlink.
if [ -L ~/.config/opencode ]; then
  ls -ld ~/.config/opencode
  printf '%s\n' 'Existing symlink found; inspect it and do not run ln again.' >&2
  exit 1
elif [ -e ~/.config/opencode ]; then
  ls -ld ~/.config/opencode
  mv ~/.config/opencode ~/.config/opencode.pre-dotfiles-$(date +%Y%m%d-%H%M%S)
fi

ln -s ~/.dotfiles/opencode/config ~/.config/opencode
```

Run this only during the later, approved deployment phase. The timestamped move
preserves the current live configuration before replacing its real directory
with the dotfiles symlink. The symlink check stops the command sequence before
`ln` can create a nested `~/.config/opencode/config` link inside an existing
symlink target.

### 1. Create `opencode.local.jsonc`

Within the symlink target, copy the applicable template to the gitignored local
layer, then fill in the machine's provider header and secrets:

```bash
cp ~/.config/opencode/opencode.local.personal.example.jsonc ~/.config/opencode/opencode.local.jsonc
# Or, on a work machine:
cp ~/.config/opencode/opencode.local.work.example.jsonc ~/.config/opencode/opencode.local.jsonc
```

### 2. Fill in secrets

Each file holds a single value with **no trailing newline** (use `printf '%s'`).
All files in `secrets/` except `README.md` are gitignored.

Context7 documentation lookups use `npx ctx7@latest library ...`, then
`npx ctx7@latest docs ...`, per `AGENTS.md`. No Context7 server or Context7
secret is required.

| File | Description |
|------|-------------|
| `github.pat` | GitHub Personal Access Token (only if the `github` MCP is enabled) |
| `homeassistant.token` | Home Assistant long-lived token (without `Bearer ` prefix) |
| `homeassistant.url` | Home Assistant MCP endpoint URL |
| `firecrawl.url` | Firecrawl MCP base URL |
| `firecrawl.key` | Firecrawl MCP API key |
| `jira.url` | Jira base URL (Atlassian MCP) |
| `jira.token` | Jira personal access token |
| `stitch.key` | Google Stitch API key |
| `alibaba-cloud.key` | Alibaba Cloud API key (optional) |

```bash
cd ~/.config/opencode
printf '%s' 'your-jwt'                            > secrets/homeassistant.token
printf '%s' 'https://ha.example.com/api/mcp'      > secrets/homeassistant.url
printf '%s' 'https://firecrawl.example.internal'  > secrets/firecrawl.url
printf '%s' 'your-firecrawl-key'                  > secrets/firecrawl.key
printf '%s' 'https://jira.example.internal'       > secrets/jira.url
printf '%s' 'your-jira-token'                     > secrets/jira.token
printf '%s' 'your-stitch-key'                     > secrets/stitch.key
```

### 3. Wire up `OPENCODE_CONFIG`

Pick **one** of the options below.

---

## Running: pointing OpenCode at the local layer

OpenCode needs `OPENCODE_CONFIG` to point at `opencode.local.jsonc`. Three ways:

### Option A — Shell alias (no extra tools)

Add to `~/.zshrc`:

```bash
alias opencode='OPENCODE_CONFIG="$HOME/.config/opencode/opencode.local.jsonc" opencode'
```

Then `source ~/.zshrc` and just run `opencode`.

If you keep two configs side by side, use two aliases instead:

```bash
alias opencode-work='OPENCODE_CONFIG="$HOME/.config/opencode/opencode.local.jsonc" opencode'
alias opencode-priv='OPENCODE_CONFIG="$HOME/.config/opencode-priv/opencode.local.jsonc" opencode'
```

### Option B — direnv (automatic per directory)

[direnv](https://direnv.net/) auto-loads `OPENCODE_CONFIG` when you `cd` into the
config dir and unloads it when you leave.

```bash
brew install direnv
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
source ~/.zshrc

cd ~/.config/opencode
direnv allow .       # approve the .envrc once
```

The committed-as-ignored `.envrc` contains:

```bash
export OPENCODE_CONFIG="$PWD/opencode.local.jsonc"
```

### Option C — Export manually (one-off)

```bash
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.local.jsonc" opencode
```

---

## Agents

See `AGENTS.md` for the full agent roster, per-agent skill whitelists, and MCP
wiring. Key points:

- MCP permission patterns are denied globally in `opencode.jsonc` and allowed
  only inside their specialist agent (`ha`, `jira`, `stitch-mcp`,
  `webscraper`/`webresearcher`/`webmonitor`, `webdebugger`).
- `jira` and `stitch-mcp` are MCP-operator agents; `stitch` is the separate
  skill-driven design-to-code agent.

---

## Verifying the setup

```bash
# config is valid JSON
jq empty opencode.jsonc && jq empty opencode.local.jsonc && echo OK

# the local layer is being applied (run with OPENCODE_CONFIG set)
opencode --version
```

To confirm two machines share an identical base:

```bash
diff <(jq -S . ~/.config/opencode-priv/opencode.jsonc) \
     <(jq -S . ~/.config/opencode/opencode.jsonc) && echo "IDENTICAL BASE"
```

---

## Layout

```
~/.config/opencode/
├── opencode.jsonc         # shared base (tracked, identical everywhere)
├── opencode.local.jsonc    # per-machine models/providers (gitignored)
├── .envrc                 # optional direnv loader (gitignored)
├── AGENTS.md              # agent roster + conventions
├── agents/               # agent definitions (*.md)
├── docs/                 # rules, specs, plans
├── secrets/              # API keys/URLs (gitignored; {file:...} refs)
├── plugins/              # superpowers.js symlink
├── skills/               # skill-discovery symlinks
└── superpowers/, anthropics-skills/, cloudflare-skills/,
    stitch-skills/, awesome-agent-skills/   # skill submodules
```
