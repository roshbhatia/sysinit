vim.opt_local.commentstring = "# %s"

Snacks.keymap.set("n", "<localleader>xr", function()
  local file = vim.fn.expand("%:p")
  vim.cmd("split | term nu " .. vim.fn.shellescape(file))
end, { ft = "nu", desc = "Run script" })
