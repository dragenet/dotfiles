# Provenance

This directory's initial structure (`opencode.jsonc`, `AGENTS.md`, `agents/*.md`,
`docs/`, `scripts/`, `secrets/`, `skill/`) was vendored from:

- Source: https://github.com/jabbas/opencode-config
- Commit: `6a85a4b3f1ae7b679aa2990717fbe19e4fc11b8e` (2026-07-03)
- Vendored: 2026-07-16, via plain file copy (no git submodule/subtree, no history)

The structure was vendored, then adapted for this user's roster, providers,
permissions, plugins, graphify workflow, and documentation. The current design
and implementation plan are
`.agents/superpowers/specs/2026-07-16-opencode-config-redesign-design.md` and
`.agents/superpowers/plans/2026-07-16-opencode-config-redesign.md`.

Deployment remains deferred: this staged tree is not symlinked or copied to the
live `~/.config/opencode`; `bootstrap.sh`, machine-local configuration, and
secrets remain untouched.
