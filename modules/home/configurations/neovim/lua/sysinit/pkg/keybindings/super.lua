local M = {}

function M.setup()
  vim.keymap.set("n", "<localleader>r", "<CMD>edit!<CR>", {
    noremap = true,
    silent = true,
    desc = "Reload current file",
  })
end

return M
