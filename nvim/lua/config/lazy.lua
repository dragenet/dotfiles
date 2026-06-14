-- Bootstrap lazy.nvim
-- If not installed, clone it from GitHub first
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- Auto-import all files from lua/plugins/*.lua
    -- Each file returns a table of plugin specs
    { import = "plugins" },
  },
  defaults = {
    lazy = false,    -- load plugins at startup unless lazy = true is set on the spec
    version = false, -- always use latest git commit (most plugins don't tag releases reliably)
  },
  checker = {
    enabled = true,  -- check for plugin updates in the background
    notify = false,  -- don't show a notification; check manually with :Lazy
  },
  change_detection = {
    notify = false,  -- don't notify when config files change
  },
})
