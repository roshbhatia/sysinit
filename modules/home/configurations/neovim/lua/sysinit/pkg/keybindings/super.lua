local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>r", function()
    vim.cmd("edit!")
  end, {
    noremap = true,
    silent = true,
    desc = "Reload current file",
  })

  vim.keymap.set("n", "<leader>x", function()
    vim.cmd("qa!")
  end, {
    noremap = true,
    silent = true,
    desc = "Force Quit",
  })
end

return M
