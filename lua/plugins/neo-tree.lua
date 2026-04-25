return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
    { "<leader>o", "<cmd>Neotree focus<cr>",  desc = "Focus file explorer" },
    { "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Reveal current file in explorer" },
  },
  opts = {
    close_if_last_window = true,
    enable_git_status = true,
    enable_diagnostics = true,
    window = {
      position = "left",
      width = 35,
      mappings = {
        ["<space>"] = "toggle_node",
        ["<cr>"]    = "open",
        ["l"]       = "open",       -- vim-style: l to open/enter
        ["h"]       = "close_node", -- vim-style: h to collapse
        ["a"]       = "add",
        ["d"]       = "delete",
        ["r"]       = "rename",
        ["R"]       = "refresh",
        ["?"]       = "show_help",
      },
    },
    filesystem = {
      follow_current_file = {
        enabled = true,
      },
      hijack_netrw_behavior = "open_default",
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = false,
        hide_dotfiles = true,
        hide_gitignored = true,
      },
    },
  },
}
