local special_filetypes = require("utils.filetypes").utility_filetypes

local function disable_decorations(win)
  local config = vim.api.nvim_win_get_config(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
  if config.relative ~= "" or vim.tbl_contains(special_filetypes, ft) then
    vim.wo[win].foldcolumn = "0"
    vim.wo[win].signcolumn = "no"
  end
end

vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    disable_decorations(vim.api.nvim_get_current_win())
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "OilEnter",
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      disable_decorations(win)
    end
  end,
})

vim.api.nvim_create_user_command("Bufonly", function()
  Snacks.bufdelete.other({
    force = true,
  })
end, {
  desc = "Delete all other buffers",
})

Snacks.keymap.set("n", "<leader>w", function()
  vim.cmd("silent! write!")
  vim.cmd("silent! xit!")
end, {
  desc = "Write and close buffer",
})
