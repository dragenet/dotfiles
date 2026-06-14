# Neovim Learning & Configuration Project

## Goal

Build a fully configured, modern Neovim-based development environment from scratch — learning how everything works along the way. The user starts with **zero vim/neovim experience**.

## Collaboration Approach

- This is a **learning-in-progress** workspace. We build incrementally, understand before adding more.
- Each phase produces working, committable config files.
- Claude explains *why* before *how* — no cargo-culting plugins.
- We reference alpha2phi's series as curriculum backbone, but use **2025-current tooling** (several articles use deprecated tools).
- All config lives here in `/Users/dominik/Projects/nvim/` and gets symlinked/copied to `~/.config/nvim/` when ready.

---

## Neovim Version Target

**Neovim 0.11+** (current stable). This unlocks built-in LSP improvements and new APIs.

---

## Canonical Stack Decisions (2025-current)

| Concern | Our Choice | Notes |
|---|---|---|
| Plugin manager | **lazy.nvim** | Replaces packer.nvim (unmaintained) |
| Inline AI completion | **copilot.lua** | GitHub Copilot ghost-text completions |
| Completion UI | **blink.cmp** | Replaces nvim-cmp (faster, new LazyVim default) |
| Formatting | **conform.nvim** | Replaces null-ls (archived); prettier + eslint both installed via mason |
| Linting | **nvim-lint** | Replaces null-ls |
| Fuzzy finder | **telescope.nvim + telescope-fzf-native** | fzf-lua is faster but telescope UX preferred |
| LSP management | **mason.nvim + nvim-lspconfig + mason-lspconfig** | Replaces nvim-lsp-installer |
| Syntax | **nvim-treesitter** (main branch) | master branch is frozen/deprecated |
| Colorscheme | **tokyonight** or **catppuccin** | — |
| AI agent | **claude-code.nvim** (unofficial) | Wraps Claude Code CLI; works with Claude Pro, no API key needed |
| Git | **gitsigns.nvim + neogit + diffview.nvim** | — |
| File explorer (sidebar) | **neo-tree.nvim** | Visual tree navigation |
| File explorer (buffer) | **oil.nvim** | Edit filesystem as plain text — great for bulk creates/renames |
| Status line | **lualine.nvim** | — |
| Key hints | **which-key.nvim** | — |

### AI Setup Rationale

- **copilot.lua** handles ghost-text completions as you type (GitHub Copilot subscription)
- **claude-code.nvim** opens Claude Code CLI in a Neovim-native toggle window — no API key needed, uses Claude Pro auth
- avante.nvim was considered but dropped: requires a paid Anthropic API key on top of Claude Pro

---

## Learning Path

### Phase 0 — Vim Fundamentals (no config needed)
Understand modal editing before touching any files.

- [ ] Modes: Normal, Insert, Visual, Command
- [ ] Essential motions: `h j k l`, `w b e`, `0 $`, `gg G`
- [ ] Editing verbs: `d c y p`, operator + motion combos (`dw`, `ci"`, `ya{`)
- [ ] Undo/redo: `u`, `Ctrl-r`
- [ ] Save/quit: `:w`, `:q`, `:wq`, `ZZ`
- [ ] Run `vimtutor` in terminal (built-in interactive tutorial)

**Reference**: `vimtutor` is the canonical resource — no articles needed.

---

### Phase 1 — init.lua & Plugin Manager
First real config. Understand the Lua entry point and lazy.nvim.

- [ ] Install Neovim 0.11+
- [ ] Understand `~/.config/nvim/init.lua` as entry point
- [ ] Set core options (line numbers, tabs, search, clipboard)
- [ ] Bootstrap lazy.nvim
- [ ] Understand plugin spec format
- [ ] Install which-key.nvim (key mapping discoverability)

**alpha2phi reference**: "Neovim for Beginners — init.lua" + "Key Mappings and WhichKey" + "Plugin Management"
**Note**: Use lazy.nvim, not packer as shown in older articles.

**Files to produce**: `init.lua`, `lua/config/options.lua`, `lua/config/keymaps.lua`, `lua/config/lazy.lua`

---

### Phase 2 — UI & Navigation
Make it look good and navigate efficiently.

- [ ] Colorscheme (tokyonight)
- [ ] Status line (lualine.nvim)
- [ ] File explorer sidebar (neo-tree.nvim)
- [ ] File explorer buffer (oil.nvim) — edit filesystem as text
- [ ] Fuzzy finder (telescope.nvim) — files, buffers, live grep
- [ ] Buffer management basics

**alpha2phi reference**: "Status Line", "File Explorer", "Fuzzy File Search (Part 1 & 2)", "User Interface"

**Files to produce**: `lua/plugins/ui.lua`, `lua/plugins/navigation.lua`

---

### Phase 3 — Editing Power
Treesitter for smart syntax, auto-pairs, comments, surround.

- [ ] nvim-treesitter (syntax highlighting, indentation, text objects)
- [ ] nvim-autopairs
- [ ] Comment.nvim (or mini.comment)
- [ ] nvim-surround
- [ ] Code folding with treesitter

**alpha2phi reference**: "Neovim 101 — Tree-sitter", "Tree-sitter Usage", "Auto Pairs", "Code Folding"

**Files to produce**: `lua/plugins/editor.lua`

---

### Phase 4 — LSP + Completion (the big one)
Language intelligence: go-to-definition, hover docs, diagnostics, completion.

- [ ] mason.nvim (install language servers)
- [ ] nvim-lspconfig (configure language servers)
- [ ] mason-lspconfig.nvim (bridge)
- [ ] blink.cmp (completion engine)
- [ ] copilot.lua (Copilot inline completions, integrated with blink.cmp)
- [ ] conform.nvim (formatting on save)
- [ ] nvim-lint (async linting)
- [ ] `lua_ls` set up immediately — needed for writing Neovim config itself
- [ ] Understand LSP diagnostics and keymaps

**alpha2phi reference**: "LSP Part 1 & 2", "LSP Plugins", "LSP Inlay Hints"
**Note**: Skip null-ls articles entirely. Use conform.nvim + nvim-lint instead.

**Files to produce**: `lua/plugins/lsp.lua`, `lua/plugins/completion.lua`, `lua/plugins/formatting.lua`

---

### Phase 5 — Git Integration
Version control without leaving Neovim.

- [ ] gitsigns.nvim (inline blame, hunk navigation, staging)
- [ ] neogit (Magit-inspired git UI)
- [ ] diffview.nvim (file diff viewer)

**alpha2phi reference**: "Source Code Control"

**Files to produce**: `lua/plugins/git.lua`

---

### Phase 6 — Snippets & Advanced Completion
- [ ] LuaSnip (snippet engine)
- [ ] Friendly-snippets (community snippet collection)
- [ ] Integrate with blink.cmp

**alpha2phi reference**: "Snippets", "Snippets using Lua"

**Files to produce**: `lua/plugins/snippets.lua`

---

### Phase 7 — Debugging & Testing
- [ ] nvim-dap (Debug Adapter Protocol)
- [ ] nvim-dap-ui
- [ ] neotest (test runner)

**alpha2phi reference**: "Debugging using DAP", "Testing", "Test Debugging and Automation"

**Files to produce**: `lua/plugins/dap.lua`, `lua/plugins/testing.lua`

---

### Phase 8 — AI Integration
- [ ] claude-code.nvim (toggle Claude Code CLI inside Neovim)
- [ ] Keybindings for open/close/send context

**alpha2phi reference**: "Modern Neovim — AI Coding", "AI Coding Plugins" (adapt — articles use avante; our approach differs)

**Files to produce**: `lua/plugins/ai.lua`

---

### Phase 9 — Language-specific PDE

Full language support for our stack. All servers installed via mason, formatters wired into conform.nvim, linters into nvim-lint.

#### Lua
| Concern | Tool |
|---|---|
| LSP | `lua_ls` (set up in Phase 4 — needed for config editing) |
| Formatter | `stylua` |
| Linter | `lua_ls` diagnostics (built-in) |

#### JavaScript / TypeScript
| Concern | Tool |
|---|---|
| LSP | `ts_ls` (TypeScript language server) |
| Formatter | `eslint` (primary for JS/TS) or `prettier` (fallback for projects not using eslint formatting) |
| Linter | `eslint` (dual role: lint + format) |
| Extra | `nvim-ts-autotag` (auto-close and rename HTML/JSX tags) |

**Note**: conform.nvim will try eslint first for JS/TS (projects with eslint config), fall back to prettier for projects using it directly. Both installed via mason in the formatting phase. HTML and CSS always use prettier.

#### HTML / CSS
| Concern | Tool |
|---|---|
| LSP | `html` (vscode-html-language-server) |
| LSP | `cssls` (vscode-css-language-server) |
| Formatter | `prettier` (opinionated, handles both HTML and CSS) |
| Extra | `nvim-ts-autotag` (shared with JS/TS above) |

#### Python
| Concern | Tool |
|---|---|
| LSP | `basedpyright` (modern fork of pyright, stricter, more features) |
| Formatter | `ruff` (replaces black + isort — fast, all-in-one) |
| Linter | `ruff` (dual role: lint + format, replaces flake8) |

#### Rust
| Concern | Tool |
|---|---|
| LSP | `rust-analyzer` |
| Formatter | `rustfmt` (built into Rust toolchain) |
| Linter | clippy (via rust-analyzer, runs automatically) |
| Extra | `rustaceanvim` (optional plugin that wraps rust-analyzer with richer Rust-specific features) |

#### Go
| Concern | Tool |
|---|---|
| LSP | `gopls` (official Go language server) |
| Formatter | `goimports` (superset of gofmt — fixes imports + formats) |
| Linter | `golangci-lint` (meta-linter, runs many linters at once) |

#### Ansible
| Concern | Tool |
|---|---|
| LSP | `ansiblels` (ansible-language-server) — only attaches to the `yaml.ansible` filetype |
| Filetype detection | `nvim-ansible` — sets `yaml.ansible` for `roles/*/tasks/`, `roles/*/handlers/`, `defaults/`, `group_vars/`, `host_vars/`, `playbooks/`, `playbook*.yml`, `molecule/` |
| Linter | `ansible-lint` (installed via `:MasonInstall ansible-lint`; runs through ansiblels) |
| Extra | `<leader>ta` runs the playbook/role under cursor via `nvim-ansible` |

#### Kubernetes / general YAML
| Concern | Tool |
|---|---|
| LSP | `yamlls` (yaml-language-server) for plain `.yaml`/`.yml` files |
| Schemas | `SchemaStore.nvim` — full SchemaStore catalog (Kubernetes manifests, GitHub Actions, docker-compose, etc.), matched by filename/content |

**alpha2phi reference**: "Neovim PDE — Web Development", "Neovim PDE — C/C++, Go, Python and Rust", "Common Language Servers"

**Files to produce**: extend `lua/plugins/lsp.lua`, `lua/plugins/formatting.lua` with per-language config; add `lua/plugins/lang.lua` for extras (autotag, rustaceanvim); add `lua/plugins/ansible.lua` for nvim-ansible

---

### Phase 10 — Polish & Quality of Life
Deferred until the core environment is fully working.

- [ ] **trouble.nvim** — project-wide diagnostics panel
- [ ] **bufferline.nvim** — visual buffer tabs at top
- [ ] **alpha.nvim** — startup dashboard with recent files
- [ ] **persistence.nvim** — session restore on reopen
- [ ] **nvim-web-devicons** — file icons (neo-tree, telescope, bufferline)
- [ ] **indent-blankline.nvim** — indentation guides
- [ ] **vim-illuminate** — highlight all occurrences of word under cursor
- [ ] **todo-comments.nvim** — highlight TODO/FIXME/NOTE in code
- [ ] **noice.nvim** — better cmdline/message UI (opinionated, optional)

---

## Config Directory Structure (target)

```
~/.config/nvim/
├── init.lua                  # entry point, bootstraps lazy.nvim
└── lua/
    ├── config/
    │   ├── options.lua       # vim.opt settings
    │   ├── keymaps.lua       # global keymaps
    │   ├── autocmds.lua      # autocommands
    │   └── lazy.lua          # lazy.nvim bootstrap
    └── plugins/
        ├── ui.lua            # colorscheme, statusline
        ├── navigation.lua    # telescope, neo-tree, oil.nvim
        ├── editor.lua        # treesitter, autopairs, surround, comments
        ├── lsp.lua           # mason, lspconfig, mason-lspconfig, per-language servers
        ├── completion.lua    # blink.cmp + copilot.lua
        ├── formatting.lua    # conform.nvim + nvim-lint
        ├── git.lua           # gitsigns, neogit, diffview
        ├── snippets.lua      # luasnip, friendly-snippets
        ├── dap.lua           # debugging
        ├── testing.lua       # neotest
        ├── lang.lua          # language extras (autotag, rustaceanvim, etc.)
        ├── ansible.lua       # nvim-ansible (yaml.ansible filetype detection, playbook runner)
        └── ai.lua            # claude-code.nvim
```

---

## Key References

- **alpha2phi series index**: https://medium.com/@alpha2phi/learn-neovim-the-practical-way-8818fcf4830f
- **alpha2phi beginner repo**: https://github.com/alpha2phi/neovim-for-beginner (main branch)
- **alpha2phi modern repo**: https://github.com/alpha2phi/modern-neovim (main branch)
- **kickstart.nvim** (single-file reference config, excellent for understanding): https://github.com/nvim-lua/kickstart.nvim
- **LazyVim** (full distro to study patterns from): https://github.com/LazyVim/LazyVim
- **lazy.nvim docs**: https://lazy.folke.io/
- **Neovim 0.11 LSP guide**: built-in `vim.lsp.config` / `vim.lsp.enable`

---

## Outdated alpha2phi Content to Skip or Adapt

| Article topic | Issue | Modern replacement |
|---|---|---|
| Package Manager Plugin (packer) | packer is dead | Use lazy.nvim instead |
| LSP using null-ls.nvim | null-ls archived | conform.nvim + nvim-lint |
| LSP Installer | replaced | Use mason.nvim |
| nvim-cmp completion articles | superseded | blink.cmp |
| Treesitter (master branch) | frozen | Use main branch |
| AI Coding (avante.nvim) | requires paid Anthropic API key | claude-code.nvim (uses Claude Pro CLI auth) |

---

## Progress Tracker

- [x] Phase 0 — Vim Fundamentals
- [x] Phase 1 — init.lua & Plugin Manager
- [x] Phase 2 — UI & Navigation
- [x] Phase 3 — Editing Power
- [x] Phase 4 — LSP + Completion
- [x] Phase 5 — Git Integration
- [ ] Phase 6 — Snippets
- [ ] Phase 7 — Debugging & Testing
- [ ] Phase 8 — AI Integration
- [x] Phase 9 — Language-specific PDE
- [x] Phase 10 — Polish & Quality of Life (bufferline and noice intentionally skipped)
