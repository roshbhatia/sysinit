local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>m", function()
    require("menu").open("default")
  end, {
    noremap = true,
    silent = true,
    desc = "Open menu",
  })

  vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", {
    noremap = true,
    silent = true,
  })
end

return M
