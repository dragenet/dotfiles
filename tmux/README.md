# tmux config

Terminal multiplexer config — persistent, detachable sessions that work the
same locally, over SSH, or inside containers. Pairs with the Neovim config in
[`../nvim/`](../nvim/) via `smart-splits.nvim` for seamless `Ctrl-hjkl`
navigation between tmux panes and Neovim splits.

## Prerequisites

```bash
brew install tmux git
```

- `tmux` — the multiplexer itself.
- `git` — to clone TPM, the plugin manager.

## Quickstart

```bash
mkdir -p ~/.config/tmux
ln -s ~/Projects/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf

# Install TPM (tmux Plugin Manager)
mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

tmux
```

Inside tmux, press `prefix + I` (capital I, default prefix is `Ctrl-b`) to
install the configured plugins (tmux-yank, tmux-resurrect, tmux-continuum).

## Cheatsheet (default prefix: `Ctrl-b`)

| Keys | Action |
|------|--------|
| `Ctrl-b %` | Split pane vertically |
| `Ctrl-b "` | Split pane horizontally |
| `Ctrl-hjkl` | Move between panes — and into Neovim splits seamlessly |
| `Alt-hjkl` | Resize the current pane/split |
| `Ctrl-b d` | Detach (session keeps running) |
| `Ctrl-b c` | New window |
| `Ctrl-b ,` | Rename window |
| `Ctrl-b [` then `v`/`y` | Enter copy mode (vi keys), select, yank to clipboard |
| `Ctrl-b Ctrl-s` / `Ctrl-b Ctrl-r` | Manually save / restore session (tmux-resurrect) |

`tmux-continuum` auto-saves the session every 15 minutes and restores it
automatically on the next `tmux` start — so reattach with `tmux attach` (or
just `tmux`, it'll find the last session) after a reboot or SSH drop.
