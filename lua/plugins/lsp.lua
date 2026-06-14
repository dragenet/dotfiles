return {
  "mason-org/mason-lspconfig.nvim",
  dependencies = {
    "mason-org/mason.nvim",  -- must be loaded first (mason-lspconfig bridges into it)
    "neovim/nvim-lspconfig", -- provides default server configs that vim.lsp.enable() picks up
    "b0o/SchemaStore.nvim",  -- JSON/YAML schema catalog (Kubernetes, GitHub Actions, etc.) for yamlls
  },
  -- We use config = function() instead of opts = {} because we need to do several
  -- things in sequence, not just call a single setup()
  config = function()

    -- ─── 1. Diagnostic display ────────────────────────────────────────────────
    -- Controls how errors/warnings from ALL language servers are shown
    vim.diagnostic.config({
      underline = true,    -- squiggly line under the problem token
      signs = true,        -- icons in the gutter (left margin)
      virtual_text = {
        prefix = "●",      -- the dot shown before the inline message
        spacing = 4,       -- spaces between end of code and the message
      },
      update_in_insert = false,  -- don't update diagnostics while typing (less noise)
      severity_sort = true,      -- errors shown above warnings above hints
    })

    -- ─── 2. Virtual text: show in normal mode only UNCOMMENT TO ENABLE──────────
    -- Hide virtual text when entering insert mode, restore it on leave
    -- Underlines and signs remain visible in both modes
    -- To compute errors live when typing enable update_in_insert
    --
    -- vim.api.nvim_create_autocmd("InsertEnter", {
    --   callback = function() vim.diagnostic.config({ virtual_text = false }) end,
    -- })
    -- vim.api.nvim_create_autocmd("InsertLeave", {
    --   callback = function()
    --     vim.diagnostic.config({ virtual_text = { prefix = "●", spacing = 4 } })
    --   end,
    -- })

    -- ─── 3. LSP keymaps (only active in buffers where LSP is running) ─────────
    -- LspAttach fires every time a language server connects to a buffer
    -- This is the modern replacement for the old on_attach callback
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
      -- clear = true means: if this group already exists, clear it before adding new commands
      -- prevents duplicate keymaps if the config is reloaded

      callback = function(event)
        -- event.buf is the buffer number the LSP just attached to
        -- { buffer = event.buf } makes each keymap local to that buffer only
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- Navigation
        map("gd", vim.lsp.buf.definition,      "Go to definition")
        map("gD", vim.lsp.buf.declaration,     "Go to declaration")
        map("gi", vim.lsp.buf.implementation,  "Go to implementation")
        map("gr", vim.lsp.buf.references,      "Go to references")
        map("K",  vim.lsp.buf.hover,           "Hover documentation")

        -- Code actions
        map("<leader>rn", vim.lsp.buf.rename,       "Rename symbol")
        map("<leader>ca", vim.lsp.buf.code_action,  "Code action")

        -- Diagnostics navigation
        -- vim.diagnostic.jump() is the 0.11+ API (replaces goto_prev/goto_next)
        map("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
        map("]d", function() vim.diagnostic.jump({ count = 1 }) end,  "Next diagnostic")
        map("<leader>d", vim.diagnostic.open_float, "Show diagnostic float")
      end,
    })

    -- ─── 4. Server-specific configuration ────────────────────────────────────
    -- vim.lsp.config() customizes a server BEFORE it starts
    -- nvim-lspconfig provides the base defaults; this merges on top of them

    -- lua_ls: tell it we're inside Neovim so it knows about the vim.* globals
    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" },  -- don't warn that 'vim' is undefined
          },
          -- workspace.library removed: lazydev.nvim handles Neovim API type definitions
          -- lazily and efficiently — no need to dump all runtime files upfront
          telemetry = { enable = false },
        },
      },
    })

    -- yamlls: validates/completes plain YAML against schemas from the SchemaStore
    -- catalog (Kubernetes manifests, GitHub Actions, docker-compose, etc.)
    -- Ansible files use the "yaml.ansible" filetype and are handled by ansiblels
    -- below instead — yamlls' default filetypes don't include yaml.ansible.
    vim.lsp.config("yamlls", {
      capabilities = {
        textDocument = {
          -- yamlls needs this to advertise folding support
          foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
          },
        },
      },
      -- Merge in the full SchemaStore catalog (Kubernetes is matched by filename,
      -- e.g. *.k8s.yaml, deployment.yaml, etc. — see schemastore.nvim docs)
      before_init = function(_, new_config)
        new_config.settings.yaml.schemas = vim.tbl_deep_extend(
          "force",
          new_config.settings.yaml.schemas or {},
          require("schemastore").yaml.schemas()
        )
      end,
      settings = {
        redhat = { telemetry = { enable = false } },
        yaml = {
          validate = true,
          format = { enable = true },
          keyOrdering = false,
          schemaStore = {
            -- must be disabled to let schemastore.nvim's catalog take over
            enable = false,
            url = "",
          },
        },
      },
    })

    -- ansiblels: powers completion/hover/diagnostics for Ansible playbooks and roles
    -- Only attaches to the "yaml.ansible" filetype (set by nvim-ansible, see lua/plugins/ansible.lua)
    -- Runs `ansible-lint` for validation — install it with :MasonInstall ansible-lint
    -- (or `pipx install ansible-lint`) if linting diagnostics don't show up.
    vim.lsp.config("ansiblels", {})

    -- ─── 4. mason-lspconfig: auto-install and auto-enable servers ─────────────
    require("mason-lspconfig").setup({
      -- These servers are installed automatically via mason on first launch
      -- Names here are lspconfig names; mason-lspconfig translates to mason package names
      ensure_installed = {
        "lua_ls",        -- Lua (for this config)
        "ts_ls",         -- TypeScript / JavaScript
        "html",          -- HTML
        "cssls",         -- CSS / SCSS / Less
        "eslint",        -- ESLint (lint + format for JS/TS)
        "basedpyright",  -- Python (modern fork of pyright)
        "rust_analyzer", -- Rust
        "gopls",         -- Go
        "yamlls",        -- YAML (incl. Kubernetes manifests via SchemaStore)
        "ansiblels",     -- Ansible playbooks/roles
      },
      -- automatic_enable = true is the default: mason-lspconfig calls vim.lsp.enable()
      -- for each installed server automatically, so you don't need to call
      -- vim.lsp.enable("ts_ls") etc. manually.
      --
      -- rust_analyzer is excluded: mason still installs the binary (it's in
      -- ensure_installed above), but rustaceanvim (lua/plugins/lang.lua) sets up
      -- its own rust-analyzer client with extra tooling. Enabling both would
      -- attach two LSP clients to the same Rust buffers.
      automatic_enable = {
        exclude = { "rust_analyzer" },
      },
    })

  end,
}
