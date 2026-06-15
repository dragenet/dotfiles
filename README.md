# dotfiles

Personal configuration for my dev environment, one directory per tool. Each
directory is symlinked into place — edit the files here, not the symlink
targets.

| Tool    | Source                  | Symlinked to                  |
|---------|-------------------------|--------------------------------|
| Neovim  | [`nvim/`](nvim/)       | `~/.config/nvim`               |
| tmux    | [`tmux/`](tmux/)       | `~/.config/tmux/tmux.conf`     |
| Ghostty | [`ghostty/`](ghostty/) | `~/Library/Application Support/com.mitchellh.ghostty/config` |

## Quickstart (new machine)

```bash
git clone git@github.com:dragenet/dotfiles.git ~/Projects/dotfiles

# Neovim
ln -s ~/Projects/dotfiles/nvim ~/.config/nvim

# tmux
mkdir -p ~/.config/tmux
ln -s ~/Projects/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf

# Ghostty (macOS)
ln -sf ~/Projects/dotfiles/ghostty/config "~/Library/Application Support/com.mitchellh.ghostty/config"
```

Then see each tool's README for first-launch steps.

## Why one repo

Both configs are meant to travel together — open Neovim inside a tmux pane
(locally, over SSH, or in a container) and get seamless `Ctrl-hjkl` navigation
between Neovim splits and tmux panes. See `nvim/CLAUDE.md` for the full
learning log and design decisions behind the Neovim setup.
