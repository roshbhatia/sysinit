local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>x", function()
    vim.cmd("silent! qa!")
  end, {
    noremap = true,
    silent = true,
    desc = "Force Quit",
  })
end

return M
