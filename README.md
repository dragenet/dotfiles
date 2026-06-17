# dotfiles

Personal configuration for my dev environment, one directory per tool. Each
directory is symlinked into place — edit the files here, not the symlink
targets.

| Tool    | Source                  | Symlinked to                  |
|---------|-------------------------|--------------------------------|
| Neovim  | [`nvim/`](nvim/)       | `~/.config/nvim`               |
| tmux    | [`tmux/`](tmux/)       | `~/.config/tmux/tmux.conf`     |
| Ghostty | [`ghostty/`](ghostty/) | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| yabai   | [`yabai/`](yabai/)     | `~/.config/yabai/yabairc` (macOS only)                        |

## Quickstart (new machine)

One-liner, works on macOS and Linux, no manual clone required:

```bash
curl -fsSL https://raw.githubusercontent.com/dragenet/dotfiles/master/bootstrap.sh | bash
```

This installs git, tmux, Neovim 0.11+, ripgrep, fd, and TPM, clones this repo
to `~/.dotfiles` (override with `DOTFILES_DIR`), and symlinks the
configs into place. Safe to re-run.

If you've already cloned the repo, run `./bootstrap.sh` from its root instead
— it detects the existing checkout and skips the clone.

To do it by hand instead:

```bash
git clone git@github.com:dragenet/dotfiles.git ~/.dotfiles

# Neovim
ln -s ~/.dotfiles/nvim ~/.config/nvim

# tmux
mkdir -p ~/.config/tmux
ln -s ~/.dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf

# Ghostty (macOS)
ln -sf ~/.dotfiles/ghostty/config "~/Library/Application Support/com.mitchellh.ghostty/config"

# yabai (macOS only)
brew install koekeishiya/formulae/yabai && brew services start yabai
mkdir -p ~/.config/yabai
ln -s ~/.dotfiles/yabai/yabairc ~/.config/yabai/yabairc
```

Then see each tool's README for first-launch steps.

## Why one repo

Both configs are meant to travel together — open Neovim inside a tmux pane
(locally, over SSH, or in a container) and get seamless `Ctrl-hjkl` navigation
between Neovim splits and tmux panes. See `nvim/CLAUDE.md` for the full
learning log and design decisions behind the Neovim setup.
