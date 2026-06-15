-- Shared helpers for gating plugins/servers on system tools that may not
-- be installed on every machine (e.g. go, cargo, ansible).
return {
  exe = function(name) return vim.fn.executable(name) == 1 end,
}
