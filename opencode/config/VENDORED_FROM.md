# Provenance

This directory's structure (`opencode.json`, `AGENTS.md`, `agents/*.md`, `docs/`,
`scripts/`, `secrets/`, `skill/`) was vendored **as-is** from:

- Source: https://github.com/jabbas/opencode-config
- Commit: `6a85a4b3f1ae7b679aa2990717fbe19e4fc11b8e` (2026-07-03)
- Vendored: 2026-07-16, via plain file copy (no git submodule/subtree, no history)

**This is raw reference material, not yet adapted.** It has NOT been:

- Trimmed to the agent roster actually needed (see open question in `HANDOFF.md`)
- Adapted for our providers (opencode-go/kilo gateway, openai, anthropic —
  source repo assumes Kilo Code only, and separately Anthropic-only)
- Reconciled with `~/.config/opencode` (the currently *live* config, untouched by
  this vendoring — see `HANDOFF.md`)
- Reconciled with the `infra-flux` repo's local `.opencode/agents` and
  `.opencode/skills` (kube1-specific subagents, `web-fast-context` migration)
- Wired into `~/.dotfiles/bootstrap.sh` or symlinked to `~/.config/opencode`
- Had its git submodules (`.gitmodules`) initialized or pruned
- Committed to the `dotfiles` repo

See `HANDOFF.md` (this directory) for the full handoff prompt / open questions
for the next session.
