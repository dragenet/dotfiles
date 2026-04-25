return {
  "windwp/nvim-autopairs",
  event = "InsertEnter", -- only needed while typing, load on entering insert mode
  opts = {
    check_ts = true,     -- use treesitter to avoid pairing inside strings/comments
    ts_config = {
      javascript = { "template_string" }, -- don't pair inside JS template literals (`${...}`)
      typescript = { "template_string" },
    },
    -- Note: blink.cmp (our completion plugin) handles bracket insertion natively
    -- via its own auto_brackets option — no extra hook needed here
  },
}
