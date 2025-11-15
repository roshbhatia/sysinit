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

  vim.keymap.set("n", "<C-q>", "<C-v>", {
    noremap = true,
    silent = true,
    desc = "Enter Visual-Block mode",
  })

  vim.keymap.set("v", "<C-q>", "<C-v>", {
    noremap = true,
    silent = true,
    desc = "Visual-Block mode from Visual",
  })
end
return M
