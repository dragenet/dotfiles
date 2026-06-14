# nvim config

Modern Neovim setup built incrementally — see [`CLAUDE.md`](CLAUDE.md) for the
full learning log, stack decisions, and phase-by-phase plan.

## Prerequisites

- **Neovim 0.11+**
- `git`
- A [Nerd Font](https://www.nerdfonts.com/) (for file/UI icons), set as your terminal font
- `ripgrep` (`rg`) — used by Telescope live grep
- `fd` — optional, speeds up Telescope file finding
- `make` + a C compiler — for `telescope-fzf-native` (skipped automatically if `make` isn't found)
- A GitHub Copilot subscription, if you want inline AI completions

Language tooling (LSPs, formatters, linters) is installed automatically via
**mason** on first launch, but some servers shell out to a runtime that must
already be on `$PATH`:

| Language     | Needs                  |
|---------------|------------------------|
| TS/JS, HTML/CSS, YAML, Ansible | Node.js |
| Go            | Go toolchain |
| Rust          | rustup (for `rustfmt`/`clippy`; `rust-analyzer` itself is installed by mason) |
| Python        | none extra (`basedpyright`/`ruff` are self-contained) |

## Quickstart

```bash
ln -s ~/Projects/dotfiles/nvim ~/.config/nvim
nvim
```

On first launch:

1. lazy.nvim bootstraps itself and installs all plugins (`:Lazy` to check status).
2. mason installs the configured LSP servers/formatters/linters in the background.
3. If using Copilot, run `:Copilot auth` and follow the device-code flow.
4. Open a file of each language you use once, so treesitter installs the
   matching parser (`:TSUpdate` to refresh later).

## Finding your way around

- Leader key is **Space**. Press it and wait — which-key pops up a menu of
  every available keymap, grouped by prefix (`f` = find/files, `g` = git,
  `h` = git hunks, `x`/`c` = diagnostics/code, `q` = sessions, etc).
- `gd`/`gr`/`K`/`<leader>rn`/`<leader>ca` — standard LSP navigation, references,
  hover, rename, code actions (active once a language server attaches).
- `<leader>gg` — open Neogit (git status UI). `<leader>gd` — diff against HEAD.
- `Ctrl-hjkl` — move between splits (and tmux panes, see `../tmux/README.md`).
