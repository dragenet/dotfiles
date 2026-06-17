-- blink.cmp: completion engine
-- Replaces nvim-cmp — faster, async, built-in fuzzy matching
-- AI source (copilot or codeium) is injected based on NVIM_PROFILE:
--   personal (default) → copilot via blink-cmp-copilot
--   work               → codeium via codeium.blink
--   minimal            → no AI source
return {
  "saghen/blink.cmp",
  version = "1.*", -- pin to stable v1; v2 is under active development with breaking changes
  dependencies = {
    "rafamadriz/friendly-snippets", -- community snippet collection (VSCode-style)
  },

  opts = function()
    local profile = vim.env.NVIM_PROFILE or "personal"
    local default_sources = { "lsp", "path", "snippets", "buffer" }
    local providers = {}

    if profile == "personal" then
      table.insert(default_sources, "copilot")
      providers.copilot = {
        name         = "copilot",
        module       = "blink-cmp-copilot",
        score_offset = 100, -- float Copilot suggestions above LSP items
        async        = true,
      }
    elseif profile == "work" then
      table.insert(default_sources, "codeium")
      providers.codeium = {
        name   = "Codeium",
        module = "codeium.blink",
        async  = true,
      }
    end

    return {
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
        default   = default_sources,
        providers = providers,
      },

      -- ─── Completion behaviour ─────────────────────────────────────────────────
      completion = {
        documentation = {
          auto_show = false, -- keep the docs window off by default; toggle with <C-space>
        },
        ghost_text = {
          enabled = true, -- previews the highlighted item inline
        },
      },

      -- ─── Fuzzy matching ───────────────────────────────────────────────────────
      -- prefer_rust_with_warning: use the prebuilt Rust binary (faster), fall back
      -- to Lua automatically if the binary isn't available for your system
      fuzzy = { implementation = "prefer_rust_with_warning" },
    }
  end,

  -- opts_extend tells lazy.nvim to *merge* sources.default across plugin specs
  -- instead of replacing it — important if another plugin adds its own source
  opts_extend = { "sources.default" },
}
