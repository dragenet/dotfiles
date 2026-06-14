-- nvim-lint: async linting via vim.diagnostic
-- Complements LSP — the LSP gives you type errors and hover docs,
-- nvim-lint runs dedicated linters that catch style/logic issues the LSP may miss.
-- JS/TS are skipped here: the eslint LSP server already provides their diagnostics.
return {
  "mfussenegger/nvim-lint",
  event = "BufReadPost", -- load after a buffer is opened (linting runs on save, see autocmd below)
  config = function()

    require("lint").linters_by_ft = {
      -- ruff catches PEP8 violations, unused imports, and other style rules
      -- basedpyright (LSP) handles type errors — both run in parallel
      python = { "ruff" },

      -- golangcilint runs many Go linters at once (errcheck, staticcheck, etc.)
      -- gopls (LSP) handles basic Go diagnostics
      go = { "golangcilint" },
    }

    -- Trigger linting after every save.
    -- BufWritePost fires after the file is written, so formatters (conform) have already run.
    vim.api.nvim_create_autocmd("BufWritePost", {
      callback = function()
        require("lint").try_lint()
      end,
    })

  end,
}
