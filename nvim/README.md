# nvim config

Modern Neovim setup built incrementally — see [`CLAUDE.md`](CLAUDE.md) for the
full learning log, stack decisions, and phase-by-phase plan.

## Prerequisites

Core tools, via Homebrew (macOS):

```bash
brew install neovim git ripgrep fd
brew install --cask font-jetbrains-mono-nerd-font   # any Nerd Font works — set it as your terminal font
xcode-select --install                              # make + a C compiler, for telescope-fzf-native
```

- **Neovim 0.11+**, `git` — required.
- `ripgrep` (`rg`) — used by Telescope live grep.
- `fd` — optional, speeds up Telescope file finding.
- A [Nerd Font](https://www.nerdfonts.com/) — for file/UI icons (neo-tree, telescope, lualine, alpha dashboard).
- `make` + a C compiler — for `telescope-fzf-native` (skipped automatically if `make` isn't found).

mason installs LSP servers/formatters/linters for you, but several of them
shell out to a language runtime that must already be on `$PATH`:

```bash
brew install node    # TS/JS, HTML/CSS, YAML, Ansible language servers (ts_ls, html, cssls, eslint, yamlls, ansiblels)
brew install go      # gopls, golangci-lint, goimports
brew install python3 # basedpyright (mason installs it into its own venv via pip)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh   # rustfmt + clippy (rust-analyzer itself is a standalone binary mason installs)
```

Optional:

- A GitHub Copilot subscription, if you want inline AI completions — run `:Copilot auth` after first launch.

## Quickstart

```bash
ln -s ~/Projects/dotfiles/nvim ~/.config/nvim
nvim
```

On first launch:

1. lazy.nvim bootstraps itself and installs all plugins (`:Lazy` to check status, `:Lazy sync` to update).
2. mason auto-installs the LSP servers listed in `lua/plugins/lsp.lua`
   (`lua_ls`, `ts_ls`, `html`, `cssls`, `eslint`, `basedpyright`, `rust_analyzer`,
   `gopls`, `yamlls`, `ansiblels`).
3. Install the formatter/linter CLIs used by `conform.lua`/`lint.lua` (not
   auto-installed):
   ```vim
   :MasonInstall stylua prettier ruff goimports golangci-lint ansible-lint
   ```
4. If using Copilot, run `:Copilot auth` and follow the device-code flow.
5. Open a file of each language you use once, so treesitter installs the
   matching parser (`:TSUpdate` to refresh later).

## Finding your way around

- Leader key is **Space**. Press it and wait — which-key pops up a menu of
  every available keymap, grouped by prefix (`f` = find/files, `g` = git,
  `h` = git hunks, `x`/`c` = diagnostics/code, `q` = sessions, etc).
- `gd`/`gr`/`K`/`<leader>rn`/`<leader>ca` — standard LSP navigation, references,
  hover, rename, code actions (active once a language server attaches).
- `<leader>gg` — open Neogit (git status UI). `<leader>gd` — diff against HEAD.
- `Ctrl-hjkl` — move between splits (and tmux panes, see `../tmux/README.md`).
