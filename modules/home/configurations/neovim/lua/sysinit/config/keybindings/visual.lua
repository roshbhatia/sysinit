local M = {}

function M.setup()
  vim.keymap.set("n", "<S-x>", "<C-v>", {
    noremap = true,
    silent = true,
    desc = "Enter Visual-Block mode",
  })

  vim.keymap.set("v", "<S-x>", "<C-v>", {
    noremap = true,
    silent = true,
    desc = "Visual-Block mode from Visual",
  })
end

return M
