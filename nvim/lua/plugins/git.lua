-- Git integration, three layers that work together:
--   gitsigns  -- ambient: sign-column markers + hunk staging while you edit
--   neogit    -- command center: status/stage/commit/branch UI (Magit-style)
--   diffview  -- dedicated multi-file diff & history viewer (neogit calls into it)
return {

  -- ─── gitsigns.nvim ──────────────────────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" }, -- attach as soon as a buffer is opened
    opts = {
      -- current_line_blame stays off by default (toggle with <leader>tb below) --
      -- showing it for every line is noisy; opt-in is friendlier while editing.
      current_line_blame = false,
      current_line_blame_opts = {
        delay = 300,        -- ms to wait before showing blame for the current line
        virt_text_pos = "eol", -- show at end of line
      },

      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- ─── Navigation ───────────────────────────────────────────────────────
        -- ]c / [c jump to the next/previous changed hunk.
        -- The vim.wo.diff check falls back to vim's own diff navigation
        -- when we're inside a :DiffviewOpen / diff-mode buffer.
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end, "Next git hunk")

        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end, "Previous git hunk")

        -- ─── Staging / resetting hunks ──────────────────────────────────────
        -- "Stage" = mark this change to be included in the next commit (like `git add -p`).
        -- "Reset" = throw away the change and restore the line(s) from the last commit.
        map("n", "<leader>hs", gitsigns.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gitsigns.reset_hunk, "Reset hunk")

        -- Visual mode versions act on the selected lines only
        map("v", "<leader>hs", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage selected lines")
        map("v", "<leader>hr", function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset selected lines")

        map("n", "<leader>hS", gitsigns.stage_buffer, "Stage entire buffer")
        map("n", "<leader>hR", gitsigns.reset_buffer, "Reset entire buffer")

        -- ─── Inspecting changes ──────────────────────────────────────────────
        map("n", "<leader>hp", gitsigns.preview_hunk, "Preview hunk")
        map("n", "<leader>hb", function()
          gitsigns.blame_line({ full = true })
        end, "Blame line (full)")
        map("n", "<leader>hd", gitsigns.diffthis, "Diff this file against index")

        -- ─── Toggles ─────────────────────────────────────────────────────────
        map("n", "<leader>tb", gitsigns.toggle_current_line_blame, "Toggle inline blame")
        map("n", "<leader>tw", gitsigns.toggle_word_diff, "Toggle word diff")
      end,
    },
  },

  -- ─── neogit ─────────────────────────────────────────────────────────────────
  {
    "NeogitOrg/neogit",
    dependencies = {
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim", -- already installed; lets neogit use telescope for branch/commit pickers
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Open Neogit (status)" },
    },
    opts = {
      -- Floating window: status UI opens as a popup overlay, doesn't disturb
      -- the current window layout. Close with q.
      kind = "floating",

      -- Explicitly wire up the integrations (both plugins are present, so these
      -- would auto-detect anyway, but being explicit documents the intent).
      integrations = {
        diffview = true,  -- "d" in the diff popup opens diffview instead of a plain diff
        telescope = true, -- branch/commit selection uses telescope pickers
      },
    },
  },

  -- ─── diffview.nvim ──────────────────────────────────────────────────────────
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
    },
    keys = {
      -- Diff the working tree against HEAD, with a file panel to jump between
      -- changed files. <tab> / <s-tab> cycle through files.
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff against HEAD" },

      -- "git log -p" for the current file: every commit that touched it, with diffs.
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },

      -- Same, but for the whole repo.
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "File history (repo)" },
    },
    opts = {},
  },
}
