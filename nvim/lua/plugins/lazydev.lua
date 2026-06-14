-- Provides fast, accurate Neovim API type definitions for lua_ls
-- Replaces the slow manual workspace.library approach:
-- instead of dumping all runtime files upfront, it lazily loads type definitions
-- only for modules you actually require() in the current buffer
return {
  "folke/lazydev.nvim",
  ft = "lua", -- only activate for Lua files — no reason to load it for anything else
  opts = {
    library = {
      -- load luv (vim.uv) types only when the buffer references vim.uv
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
  },
}
