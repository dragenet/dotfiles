local opt = vim.opt

-- Line numbers
opt.number = true           -- show absolute line number on current line
opt.relativenumber = true   -- show relative numbers on all other lines (great for jump commands like 5j)

-- Tabs & indentation
opt.expandtab = true        -- insert spaces when Tab is pressed
opt.shiftwidth = 2          -- spaces used for >> and << indent commands
opt.tabstop = 2             -- how many spaces a Tab character visually takes
opt.smartindent = true      -- auto-indent new lines based on syntax

-- Search
opt.ignorecase = true       -- case-insensitive search...
opt.smartcase = true        -- ...unless you type an uppercase letter
opt.hlsearch = true         -- highlight all search matches
opt.incsearch = true        -- show matches as you type

-- UI
opt.wrap = false            -- don't wrap long lines (scroll horizontally instead)
opt.scrolloff = 8           -- keep 8 lines visible above/below cursor when scrolling
opt.sidescrolloff = 8       -- keep 8 columns visible left/right when scrolling
opt.signcolumn = "yes"      -- always show the sign column (prevents layout jumping on LSP errors)
opt.cursorline = true       -- highlight the line the cursor is on
opt.termguicolors = true    -- enable 24-bit colour (required by most colorschemes)
opt.colorcolumn = "100"     -- vertical ruler at column 100

-- Splits
opt.splitbelow = true       -- horizontal splits open below
opt.splitright = true       -- vertical splits open to the right

-- Files & history
opt.swapfile = false        -- don't create .swp files
opt.backup = false          -- don't create backup files
opt.undofile = true         -- persist undo history across sessions (saved to undodir)
opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- Clipboard
opt.clipboard = "unnamedplus" -- use system clipboard for all yank/paste operations

-- Behaviour
opt.mouse = "a"             -- enable mouse in all modes
opt.timeoutlen = 300        -- ms to wait for a key sequence (affects which-key popup speed)
opt.updatetime = 250        -- ms until CursorHold fires (affects gitsigns, LSP hover delay)
opt.completeopt = "menu,menuone,noselect" -- completion menu behaviour (used by blink.cmp later)
