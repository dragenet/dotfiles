-- Language-specific extras that don't fit cleanly into lsp/conform/lint:
--   nvim-ts-autotag -- auto-close & rename matching HTML/JSX/TSX tags
--   rustaceanvim    -- richer Rust support on top of rust-analyzer
return {

  -- ─── nvim-ts-autotag ────────────────────────────────────────────────────────
  -- Typing <div> automatically inserts the closing </div>, and editing the
  -- opening tag's name renames the closing tag to match. Relies on the
  -- treesitter parsers for each filetype (already installed for html/js/ts).
  {
    "windwp/nvim-ts-autotag",
    ft = { "html", "javascript", "javascriptreact", "typescript", "typescriptreact", "xml" },
    opts = {},
  },

  -- ─── rustaceanvim ───────────────────────────────────────────────────────────
  -- A filetype plugin: it only activates for "rust" buffers, so lazy = false
  -- here is correct (lazy.nvim shouldn't defer-load it any further).
  -- It configures its own rust-analyzer LSP client with extra tools
  -- (:RustLsp runnables/debuggables/expandMacro/etc.) — rust_analyzer must
  -- NOT also be enabled via lspconfig/mason-lspconfig, see lsp.lua.
  -- cond: only load on machines with a Rust toolchain installed.
  {
    "mrcjkb/rustaceanvim",
    version = "^9",
    lazy = false,
    cond = function() return require("config.has").exe("cargo") end,
  },
}
