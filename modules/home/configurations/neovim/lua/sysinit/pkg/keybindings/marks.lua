local M = {}

function M.setup()
  vim.keymap.set("n", "m", "<Nop>", {
    noremap = true,
    silent = true,
    desc = "Disabled mark functionality",
  })

  vim.keymap.set("v", "m", "<Nop>", {
    noremap = true,
    silent = true,
    desc = "Disabled mark functionality",
  })
end

return M
