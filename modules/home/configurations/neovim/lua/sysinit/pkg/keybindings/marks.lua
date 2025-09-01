local M = {}

function M.setup()
  vim.keymap.set("n", "m", "<Nop>", {
    noremap = true,
    silent = true,
    desc = "Mark disabled",
  })

  vim.keymap.set("v", "m", "<Nop>", {
    noremap = true,
    silent = true,
    desc = "Mark disabled",
  })
end

return M
