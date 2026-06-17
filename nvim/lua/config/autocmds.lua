local autoread_group = vim.api.nvim_create_augroup("autoread", { clear = true })

-- Trigger checktime so autoread actually picks up external file changes.
-- FocusGained  = returning to editor from another app
-- BufEnter     = switching buffers
-- CursorHold/I = idle in normal or insert mode (fires after updatetime ms)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = autoread_group,
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})
