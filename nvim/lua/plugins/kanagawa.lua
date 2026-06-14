-- Variants: "kanagawa-wave" (default dark), "kanagawa-dragon" (darker), "kanagawa-lotus" (light)
return {
  "rebelot/kanagawa.nvim",
  lazy = false,    -- must load at startup — colorscheme must be set before anything renders
  priority = 1000, -- load before all other plugins
  opts = {
    compile = false,
    transparent = false,
    dimInactive = false,
    terminalColors = true,
    theme = "wave",
    background = {
      dark = "wave",   -- used when vim.o.background = "dark"
      light = "lotus", -- used when vim.o.background = "light"
    },
  },
  config = function(_, opts)
    require("kanagawa").setup(opts)
    vim.cmd.colorscheme("kanagawa-wave")
  end,
}
