-- nvim-ansible: detects Ansible playbooks/roles and sets filetype to "yaml.ansible"
-- (plain *.yml files don't otherwise look any different from regular YAML).
-- This is what lets ansiblels (lua/plugins/lsp.lua) and the treesitter yaml
-- highlighting (lua/plugins/treesitter.lua) target Ansible files specifically.
return {
  "mfussenegger/nvim-ansible",
  ft = { "yaml" },
  keys = {
    {
      "<leader>ta",
      function() require("ansible").run() end,
      ft = "yaml.ansible",
      desc = "Ansible: run playbook/role",
    },
  },
}
