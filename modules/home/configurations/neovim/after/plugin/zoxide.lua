vim.api.nvim_create_user_command("Z", function()
  Snacks.picker.zoxide()
end, {
  desc = "Open picker with Zoxide ranked folders",
})
