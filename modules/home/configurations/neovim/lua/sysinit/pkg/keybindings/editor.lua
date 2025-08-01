local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>em", function()
    require("menu").open("default")
  end, {
    noremap = true,
    silent = true,
    desc = "Open menu from editor",
  })

  vim.keymap.set("n", "<leader>el", function()
    require("menu").open("lsp")
  end, {
    noremap = true,
    silent = true,
    desc = "Open LSP menu",
  })

  vim.keymap.set("n", "<leader>en", function()
    if vim.wo.relativenumber then
      vim.wo.relativenumber = false
      vim.wo.number = true
    else
      vim.wo.relativenumber = true
      vim.wo.number = true
    end
  end, {
    noremap = true,
    silent = true,
    desc = "Toggle line numbers",
  })

  vim.keymap.set("n", "<localleader>ew", function()
    vim.wo.wrap = not vim.wo.wrap
  end, {
    noremap = true,
    silent = true,
    desc = "Toggle line wrapping",
  })
end

return M
