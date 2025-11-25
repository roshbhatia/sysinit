local M = {}

function M.setup()
  vim.keymap.set("n", "m", "<Nop>", {
    silent = true,
    desc = "Mark disabled",
  })

  vim.keymap.set("v", "m", "<Nop>", {
    silent = true,
    desc = "Mark disabled",
  })
end

return M
