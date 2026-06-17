-- Windsurf (Codeium) AI completions — work profile only
-- Replaces Copilot where company policy prohibits it.
-- blink.cmp source is wired in completion.lua via NVIM_PROFILE detection.
-- First-time setup: run :Codeium Auth and paste the browser token.
return {
  "Exafunction/codeium.nvim",
  cond         = function() return vim.env.NVIM_PROFILE == "work" end,
  cmd          = { "Codeium" },
  event        = "InsertEnter",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts         = { enable_cmp_source = false },
}
