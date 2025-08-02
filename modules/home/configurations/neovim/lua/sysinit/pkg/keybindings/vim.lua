local M = {}

function M.setup()
  vim.keymap.set("n", "<localleader>L", "<CMD>Lazy<CR>", {
    noremap = true,
    silent = true,
    desc = "Open Lazy plugin manager",
  })
end

return M
