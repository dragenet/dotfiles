-- GitHub Copilot AI completions — personal profile only
-- suggestion and panel are disabled here because blink-cmp-copilot takes over:
-- Copilot suggestions appear inside the blink.cmp completion menu instead of
-- as separate ghost text, so copilot.lua only needs to manage the LSP connection
local is_personal = function() return (vim.env.NVIM_PROFILE or "personal") == "personal" end

return {
  {
    "zbirenbaum/copilot.lua",
    cond  = is_personal,
    event = "InsertEnter",
    opts  = {
      suggestion = { enabled = false }, -- blink.cmp handles display
      panel      = { enabled = false }, -- not needed with blink integration
    },
  },
  {
    "giuxtaposition/blink-cmp-copilot",
    cond = is_personal,
  },
}
