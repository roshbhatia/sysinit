local M = {}

function M.setup()
  vim.keymap.set("n", "<leader><leader>", ":", { desc = "Command" })

  vim.keymap.set("n", "<leader>X", function()
    vim.cmd("silent! qa!")
  end, {
    noremap = true,
    silent = true,
    desc = "Force quit",
  })
end

return M
