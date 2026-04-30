return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",   -- stable API for Neovim 0.11+/0.12; "main" is an incompatible rewrite requiring nightly
  build = ":TSUpdate", -- keeps parsers in sync with the library after each plugin update
  -- Loaded eagerly: lazy-loading on BufReadPre races with Neovim's highlighter,
  -- which calls query.get() before nvim-treesitter's queries/ dir is on the runtimepath,
  -- caching a nil result and silently breaking highlights for the whole session.
  lazy = false,
  cmd = { "TSInstall", "TSUpdate", "TSUpdateSync", "TSInstallInfo", "TSUninstall" },
  config = function()
    -- Note: on the master branch the module is "nvim-treesitter.configs", not "nvim-treesitter"
    -- The main branch uses a different API — don't mix docs from the two branches
    require("nvim-treesitter.configs").setup({

      -- Parsers that are always installed
      -- "vim/vimdoc/query" are needed by Neovim's own treesitter UI
      -- "markdown/markdown_inline" are needed by many plugins (e.g. LSP hover docs)
      ensure_installed = {
        "vim", "vimdoc", "query",
        "markdown", "markdown_inline",
        "lua", "javascript", "typescript", "tsx",
        "html", "css", "python", "rust", "go",
        "json", "yaml", "bash",
      },

      -- Automatically install a parser when you open a file type not in ensure_installed
      -- Requires a C compiler (you have one via Xcode tools)
      auto_install = true,

      -- Better syntax highlighting — replaces Neovim's regex-based highlighting
      highlight = {
        enable = true,
        -- Running both treesitter AND regex highlighting causes flickering and slowdown
        -- Keep this false unless you notice specific highlighting gaps
        additional_vim_regex_highlighting = false,
      },

      -- Treesitter-aware indentation — understands block structure rather than just counting spaces
      -- This makes = (re-indent) and auto-indent on newline much smarter
      indent = {
        enable = true,
      },

      -- Expand/shrink visual selection by walking the syntax tree
      -- More precise than character or line-based selection
      --
      -- How to use:
      --   <CR>   (Normal) — start selection at the node under cursor
      --   <CR>   (Visual) — expand to the next larger syntax node
      --   <S-CR> (Visual) — jump directly to enclosing scope (skips intermediate nodes)
      --   <BS>   (Visual) — shrink selection back one node
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection    = "<CR>",   -- start in Normal mode
          node_incremental  = "<CR>",   -- expand in Visual mode
          scope_incremental = "<S-CR>", -- jump to enclosing scope in Visual mode
          node_decremental  = "<BS>",   -- shrink in Visual mode
        },
      },

    })
  end,
}
