-- Phase 10 polish: small, mostly independent quality-of-life additions.
-- (nvim-web-devicons is already pulled in as a dependency of oil.nvim/neo-tree.nvim)
return {

  -- ─── trouble.nvim ───────────────────────────────────────────────────────────
  -- Project-wide list views for diagnostics, LSP results, todos, etc. in a
  -- dedicated panel — complements the single-line <leader>d diagnostic float
  -- and gr/references jumps we already have.
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (workspace)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (buffer)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols outline" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP definitions/references" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
    },
  },

  -- ─── persistence.nvim ───────────────────────────────────────────────────────
  -- Saves your window layout + open buffers per working directory and lets you
  -- restore it. Session files are written automatically on exit.
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore session (cwd)" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't save session on exit" },
    },
  },

  -- ─── indent-blankline.nvim ──────────────────────────────────────────────────
  -- Vertical guides for each indent level. "Scope" highlighting (which
  -- underlines/colors the guide for the block your cursor is in, via
  -- treesitter) is enabled by default — no extra option needed.
  -- We just exclude UI buffers where indent guides don't make sense.
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      indent = { char = "│" },
      exclude = {
        filetypes = {
          "alpha", "neo-tree", "lazy", "mason",
          "help", "Trouble", "trouble", "lspinfo", "checkhealth",
        },
      },
    },
  },

  -- ─── vim-illuminate ─────────────────────────────────────────────────────────
  -- Highlights other occurrences of the symbol under the cursor (via LSP,
  -- falling back to treesitter, then regex). Jump between them with the
  -- default <a-n> / <a-p> mappings.
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("illuminate").configure({
        delay = 200,
      })
    end,
  },

  -- ─── todo-comments.nvim ─────────────────────────────────────────────────────
  -- Highlights TODO/FIXME/HACK/WARN/PERF/NOTE/TEST comments and lets you jump
  -- between them or list them all via Telescope.
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO comment" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous TODO comment" },
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
    },
  },

  -- ─── alpha.nvim ─────────────────────────────────────────────────────────────
  -- Startup dashboard shown when Neovim opens with no file argument.
  -- The "dashboard" theme needs no extra icon dependencies.
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")
      local button = dashboard.button

      dashboard.section.buttons.val = {
        button("f", "  Find file", "<cmd>Telescope find_files<cr>"),
        button("r", "  Recent files", "<cmd>Telescope oldfiles<cr>"),
        button("g", "  Live grep", "<cmd>Telescope live_grep<cr>"),
        button("s", "  Restore session", "<cmd>lua require('persistence').load()<cr>"),
        button("e", "  New file", "<cmd>enew<cr>"),
        button("q", "  Quit", "<cmd>qa<cr>"),
      }

      -- Footer: show how many plugins lazy.nvim loaded and how long startup took
      local stats = require("lazy").stats()
      local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
      dashboard.section.footer.val = "Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms"

      alpha.setup(dashboard.config)
    end,
  },
}
