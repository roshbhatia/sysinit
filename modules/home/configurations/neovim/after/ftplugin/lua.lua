vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Keymaps
Snacks.keymap.set("n", "<localleader>x", "<cmd>source %<cr>", { ft = "lua", desc = "Source current file" })
Snacks.keymap.set("v", "<localleader>x", ":lua<cr>", { ft = "lua", desc = "Execute selection" })

-- Neovim Lua development helpers
local filename = vim.fn.expand("%:p")
if filename:match("%.config/nvim") or filename:match("nvim%-") or filename:match("lua/sysinit") then
  -- This is a Neovim config file
  Snacks.keymap.set("n", "<localleader>r", "<cmd>Lazy reload<cr>", { ft = "lua", desc = "Reload Neovim config" })
  Snacks.keymap.set("n", "<localleader>h", "<cmd>checkhealth<cr>", { ft = "lua", desc = "Check health" })
end

-- Print value under cursor
Snacks.keymap.set(
  "n",
  "<localleader>p",
  "yiw<cmd>lua print(vim.inspect(<C-r>0))<cr>",
  { ft = "lua", desc = "Print value under cursor" }
)
