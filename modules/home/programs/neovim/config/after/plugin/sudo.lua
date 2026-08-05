vim.api.nvim_create_user_command("Wsudo", function()
  local file = vim.fn.expand("%")
  local cmd = string.format('write !sudo tee "%s" > /dev/null', file)

  vim.api.nvim_command("silent " .. cmd)
  vim.api.nvim_command("edit!")
end, {
  desc = "Save current buffer with sudo",
})
