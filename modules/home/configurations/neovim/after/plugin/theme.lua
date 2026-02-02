vim.api.nvim_create_user_command("Colorscheme", function()
  require("snacks").picker.colorschemes({ layout = "right" })
end, {})
