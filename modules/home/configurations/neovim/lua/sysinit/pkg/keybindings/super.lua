local M = {}

function M.setup()
  vim.keymap.set("n", "<localleader>r", function() vim.cmd("edit!") end, {
    noremap = true,
    silent = true,
    desc = "Reload current file",
  })
end

return M
