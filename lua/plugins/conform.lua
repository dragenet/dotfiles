-- conform.nvim: format-on-save for all languages
-- Replaces null-ls (archived). Each formatter must be installed separately via Mason.
-- Run :ConformInfo to see what's active in the current buffer.
return {
  "stevearc/conform.nvim",
  event = "BufWritePre", -- load just before saving so format-on-save is always available
  cmd   = "ConformInfo",
  opts = {

    -- ─── Formatters per filetype ──────────────────────────────────────────────
    formatters_by_ft = {
      lua = { "stylua" },

      -- Web: lsp_format = "prefer" tries the eslint LSP formatter first.
      -- The eslint LSP reads the project's eslint config, so it only applies
      -- formatting rules the project actually defines (e.g. eslint-plugin-prettier).
      -- If the LSP can't format (no formatting rules configured), prettier runs instead.
      -- HTML and CSS always use prettier — no eslint formatting rules apply there.
      javascript      = { "prettier", lsp_format = "prefer" },
      typescript      = { "prettier", lsp_format = "prefer" },
      javascriptreact = { "prettier", lsp_format = "prefer" },
      typescriptreact = { "prettier", lsp_format = "prefer" },
      html            = { "prettier" },
      css             = { "prettier" },
      json            = { "prettier" },
      yaml            = { "prettier" },

      -- Python: organise imports first, then format (ruff replaces isort + black)
      python = { "ruff_organize_imports", "ruff_format" },

      -- Rust: rustfmt ships with the Rust toolchain, so no mason install needed.
      -- lsp_format = "fallback" means: if rustfmt isn't on PATH, let rust_analyzer format.
      rust = { "rustfmt", lsp_format = "fallback" },

      -- Go: goimports = gofmt + auto import management (superset of gofmt)
      go = { "goimports" },
    },

    -- ─── Format on save ───────────────────────────────────────────────────────
    -- lsp_format = "fallback" means: if no conform formatter is configured or available
    -- for the current filetype, fall back to vim.lsp.buf.format() as a safety net
    format_on_save = {
      timeout_ms = 500,
      lsp_format  = "fallback",
    },

  },
}
