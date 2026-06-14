# dotfiles

Personal dotfiles monorepo — one directory per tool, each symlinked into
place (see [`README.md`](README.md)).

## Collaboration approach

- **Always read official docs before discussing config options or writing
  code** for any plugin/tool — no answers from training-knowledge memory.
- This is a learning-in-progress setup (the user started with zero vim
  experience). Explain *why* before *how*; ask before deciding on
  commonly-configured options rather than choosing unilaterally.

## Subdirectories

- [`nvim/`](nvim/CLAUDE.md) — Neovim config. Has its own detailed `CLAUDE.md`
  with a phased learning plan, stack decisions, and progress tracker. This is
  the primary, most actively developed piece.
- [`tmux/`](tmux/CLAUDE.md) — tmux config. Pairs with `nvim/` via
  `smart-splits.nvim` for seamless pane/split navigation.

## Cross-cutting notes

- The user's company doesn't allow Claude Code, so any AI-assistant plugin
  (e.g. `claude-code.nvim`, planned for `nvim/` Phase 8) must be gated to the
  personal machine only — see the `NVIM_PROFILE` env var approach noted in
  `nvim/CLAUDE.md`.
- Motivation for this repo existing (vs. one repo per tool): the environment
  should work identically over SSH and inside containers, with tmux providing
  persistent/detachable sessions.
