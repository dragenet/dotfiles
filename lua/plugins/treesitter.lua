return {
  "nvim-treesitter/nvim-treesitter",
  -- main branch required for Neovim 0.12+; master branch explicitly does not support 0.12
  branch = "main",
  build = ":TSUpdate",
  lazy = false,
  config = function()
    require("nvim-treesitter").setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    -- Ansible playbooks use the "yaml.ansible" filetype (set by nvim-ansible) but
    -- there's no separate "ansible" grammar — reuse the yaml parser for highlighting.
    vim.treesitter.language.register("yaml", "yaml.ansible")

    -- Enable treesitter highlighting for every filetype that has a parser.
    -- vim.treesitter.start() is Neovim's built-in API; pcall silently skips filetypes with no parser.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "*",
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })

    -- Treesitter-aware indentation for languages we care about.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {
        "lua", "javascript", "typescript", "tsx",
        "html", "css", "python", "rust", "go",
        "json", "yaml", "yaml.ansible", "bash",
      },
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
