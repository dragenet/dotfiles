return {
  "mason-org/mason.nvim",
  -- opts = {} is lazy.nvim shorthand:
  -- when a plugin only needs require("plugin").setup({}), you pass opts instead of config
  -- lazy.nvim calls setup() with your opts table automatically
  opts = {},
  -- expose :Mason and friends even before any LSP loads
  cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate" },
}
