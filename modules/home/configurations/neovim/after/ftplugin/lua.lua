-- Lua-specific settings and keymaps

-- Formatting
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Keymaps
local map = vim.keymap.set
local opts = { buffer = true, silent = true }

-- Lua execution
map("n", "<localleader>lx", "<cmd>source %<cr>", vim.tbl_extend("force", opts, { desc = "Lua: Source current file" }))
map("v", "<localleader>lx", ":lua<cr>", vim.tbl_extend("force", opts, { desc = "Lua: Execute selection" }))

-- Neovim Lua development helpers
local filename = vim.fn.expand("%:p")
if filename:match("%.config/nvim") or filename:match("nvim%-") or filename:match("lua/sysinit") then
  -- This is a Neovim config file
  map(
    "n",
    "<localleader>lr",
    "<cmd>Lazy reload<cr>",
    vim.tbl_extend("force", opts, { desc = "Lua: Reload Neovim config" })
  )
  map("n", "<localleader>lh", "<cmd>checkhealth<cr>", vim.tbl_extend("force", opts, { desc = "Lua: Check health" }))
end

-- Print value under cursor
map(
  "n",
  "<localleader>lp",
  "yiw<cmd>lua print(vim.inspect(<C-r>0))<cr>",
  vim.tbl_extend("force", opts, { desc = "Lua: Print value under cursor" })
)
