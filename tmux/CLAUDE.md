# tmux config

Added to give the dev environment persistent/detachable sessions that work
the same locally, over SSH, and inside containers — and to pair with
`../nvim/` for seamless pane/split navigation.

## Collaboration approach

Same as the rest of this repo: read official docs before discussing config
options, explain *why* before *how*, ask before deciding on commonly
configured options (prefix key, plugin choices, etc).

## Current state

- Config: [`tmux.conf`](tmux.conf), symlinked to `~/.config/tmux/tmux.conf`
  (tmux's XDG config location — TPM also installs plugins under
  `~/.config/tmux/plugins/`, while the TPM script itself lives at
  `~/.tmux/plugins/tpm`).
- Prefix kept at default `Ctrl-b` (user's choice — explicitly declined
  remapping to `Ctrl-a`).
- `smart-splits.nvim` integration: `Ctrl-hjkl`/`Alt-hjkl` bindings detect
  `@pane-is-vim` and forward to Neovim when appropriate.
- TPM plugins: `tmux-yank` (clipboard, OSC52-aware for SSH), `tmux-resurrect`
  + `tmux-continuum` (session persistence/auto-restore).

## Known gaps

- Ghostty (the user's terminal) is **not** in smart-splits.nvim's supported
  multiplexer list (only tmux, Zellij, WezTerm, Kitty) — so `Ctrl-hjkl`
  navigation only spans tmux panes + Neovim splits, not Ghostty's own native
  splits/tabs. tmux is the multiplexer layer for this reason.
