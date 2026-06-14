-- Seamless Ctrl-hjkl navigation between Neovim splits AND tmux panes.
-- The tmux side (Ctrl-hjkl bindings + @pane-is-vim detection) lives in
-- ~/Projects/dotfiles/tmux/tmux.conf.
return {
  "mrjones2014/smart-splits.nvim",
  -- Must load at startup (not lazy): it needs to set the tmux @pane-is-vim
  -- variable immediately so tmux's keybindings can detect Neovim is running.
  lazy = false,
  opts = {
    ignored_buftypes = { "nofile", "quickfix", "prompt" },
    ignored_filetypes = { "neo-tree" },
    default_amount = 3,
  },
  keys = {
    -- Move cursor between splits/panes
    { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Go to left split/pane" },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Go to below split/pane" },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Go to above split/pane" },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Go to right split/pane" },

    -- Resize splits/panes
    { "<A-h>", function() require("smart-splits").resize_left() end, desc = "Resize split/pane left" },
    { "<A-j>", function() require("smart-splits").resize_down() end, desc = "Resize split/pane down" },
    { "<A-k>", function() require("smart-splits").resize_up() end, desc = "Resize split/pane up" },
    { "<A-l>", function() require("smart-splits").resize_right() end, desc = "Resize split/pane right" },
  },
}
