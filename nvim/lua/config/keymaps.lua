-- vim.keymap.set(mode, lhs, rhs, opts)
-- mode: "n" = normal, "i" = insert, "v" = visual, "x" = visual block
-- lhs:  the key(s) you press
-- rhs:  what it does (command or function)
-- opts: table of options; desc= shows up in which-key

local map = vim.keymap.set

-- Leader key: Space
-- Must be set before lazy.nvim loads (plugins may use <leader> in their own mappings)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ─── Window navigation ────────────────────────────────────────────────────────
-- Ctrl+hjkl moves between splits (and, via smart-splits.nvim, tmux panes too)
-- See lua/plugins/smart-splits.lua

-- ─── Buffer navigation ────────────────────────────────────────────────────────
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>",     { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- ─── Search ───────────────────────────────────────────────────────────────────
-- Clear search highlight with Escape in normal mode
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- ─── Indenting ────────────────────────────────────────────────────────────────
-- Stay in visual mode after indenting (default behaviour exits visual mode)
map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

-- ─── Moving lines ─────────────────────────────────────────────────────────────
-- Move selected lines up/down with Alt+j/k
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move lines down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move lines up" })

-- ─── Miscellaneous ────────────────────────────────────────────────────────────
-- Save file
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Better up/down on wrapped lines (moves by visual line, not file line)
map({ "n", "v" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down" })
map({ "n", "v" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up" })
