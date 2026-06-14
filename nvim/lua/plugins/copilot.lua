-- GitHub Copilot AI completions
-- suggestion and panel are disabled here because blink-cmp-copilot takes over:
-- Copilot suggestions appear inside the blink.cmp completion menu instead of
-- as separate ghost text, so copilot.lua only needs to manage the LSP connection
return {
  "zbirenbaum/copilot.lua",
  event = "InsertEnter",
  opts = {
    suggestion = { enabled = false }, -- blink.cmp handles display
    panel     = { enabled = false }, -- not needed with blink integration
  },
}
