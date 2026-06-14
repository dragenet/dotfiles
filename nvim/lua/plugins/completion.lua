-- blink.cmp: completion engine
-- Replaces nvim-cmp — faster, async, built-in fuzzy matching
-- blink-cmp-copilot adds GitHub Copilot as a completion source inside the menu
return {
  "saghen/blink.cmp",
  version = "1.*", -- pin to stable v1; v2 is under active development with breaking changes
  dependencies = {
    "rafamadriz/friendly-snippets",  -- community snippet collection (VSCode-style)
    "zbirenbaum/copilot.lua",        -- must be loaded before blink-cmp-copilot activates
    "giuxtaposition/blink-cmp-copilot",
  },

  opts = {
    -- ─── Keymaps ──────────────────────────────────────────────────────────────
    -- super-tab: Tab accepts the selected item (or the first item if none is
    -- highlighted), S-Tab navigates backward, C-space opens the menu manually
    keymap = { preset = "super-tab" },

    -- ─── Appearance ───────────────────────────────────────────────────────────
    appearance = {
      -- "mono" aligns icons correctly with Nerd Fonts in most terminals
      nerd_font_variant = "mono",
    },

    -- ─── Sources ──────────────────────────────────────────────────────────────
    sources = {
      -- Order matters: items are grouped and sorted within each source
      -- copilot has score_offset = 100 so its suggestions sort to the top
      default = { "lsp", "path", "snippets", "buffer", "copilot" },

      providers = {
        copilot = {
          name   = "copilot",
          module = "blink-cmp-copilot",
          score_offset = 100, -- float Copilot suggestions above LSP items
          async        = true, -- Copilot is async; don't block the menu on it
        },
      },
    },

    -- ─── Completion behaviour ─────────────────────────────────────────────────
    completion = {
      documentation = {
        auto_show = false, -- keep the docs window off by default; toggle with <C-space>
      },
      ghost_text = {
        enabled = true, -- previews the highlighted item inline (like Copilot ghost text)
      },
    },

    -- ─── Fuzzy matching ───────────────────────────────────────────────────────
    -- prefer_rust_with_warning: use the prebuilt Rust binary (faster), fall back
    -- to Lua automatically if the binary isn't available for your system
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },

  -- opts_extend tells lazy.nvim to *merge* sources.default across plugin specs
  -- instead of replacing it — important if another plugin adds its own source
  opts_extend = { "sources.default" },
}
