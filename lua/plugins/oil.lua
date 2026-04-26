-- Edit the filesystem like a text buffer:
-- rename/move/create/delete by editing text, then saving with :w
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
  },
  opts = {
    default_file_explorer = false, -- neo-tree handles netrw hijacking
    columns = { "icon" },
    view_options = {
      show_hidden = true,
      natural_order = true,
      sort = { { "type", "asc" }, { "name", "asc" } },
    },
    -- Remap <C-s>/<C-h> — conflicts with our global save and split navigation
    keymaps = {
      ["<C-s>"] = false,
      ["<C-v>"] = { "actions.select", opts = { vertical = true } },
      ["<C-h>"] = false,
      ["<C-x>"] = { "actions.select", opts = { horizontal = true } },
    },
  },
}
