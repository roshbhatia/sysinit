local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>bn", function()
    goto_buffer(1)
  end, {
    noremap = true,
    silent = true,
    desc = "Buffer next",
  })

  vim.keymap.set("n", "<leader>bp", function()
    goto_buffer(-1)
  end, {
    noremap = true,
    silent = true,
    desc = "Buffer previous",
  })
end

return M
