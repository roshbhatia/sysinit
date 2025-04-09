-- WezTerm integration with Neovim
-- This adds better integration for multiplexing, panes, and navigation

local M = {}

M.setup = function()
  -- Set terminal colors to match Neovim
  vim.g.terminal_color_0 = "#1a1b26"
  vim.g.terminal_color_1 = "#f7768e"
  vim.g.terminal_color_2 = "#9ece6a"
  vim.g.terminal_color_3 = "#e0af68"
  vim.g.terminal_color_4 = "#7aa2f7"
  vim.g.terminal_color_5 = "#bb9af7"
  vim.g.terminal_color_6 = "#7dcfff"
  vim.g.terminal_color_7 = "#a9b1d6"
  vim.g.terminal_color_8 = "#414868"
  vim.g.terminal_color_9 = "#f7768e"
  vim.g.terminal_color_10 = "#9ece6a"
  vim.g.terminal_color_11 = "#e0af68"
  vim.g.terminal_color_12 = "#7aa2f7"
  vim.g.terminal_color_13 = "#bb9af7"
  vim.g.terminal_color_14 = "#7dcfff"
  vim.g.terminal_color_15 = "#c0caf5"

  -- Set termguicolors
  vim.opt.termguicolors = true

  -- Improve terminal integration
  vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "*",
    callback = function()
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.opt_local.signcolumn = "no"
      vim.cmd("startinsert")
    end,
  })

  -- Automatically enter insert mode when switching to a terminal window
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "term://*",
    callback = function()
      vim.cmd("startinsert")
    end,
  })

  -- Fix cursor shapes in terminal mode
  if os.getenv("TERM") == "wezterm" then
    -- Block in normal mode
    vim.opt.guicursor = vim.opt.guicursor + "n-v-c:block-Cursor/lCursor"
    -- Vertical bar in insert mode
    vim.opt.guicursor = vim.opt.guicursor + "i-ci:ver25-Cursor/lCursor"
    -- Underline in replace mode
    vim.opt.guicursor = vim.opt.guicursor + "r:hor20-Cursor/lCursor"
  end

  -- Set up keybindings for terminal and window navigation
  -- These match WezTerm's default keybindings for consistency
  local term_opts = { noremap = true, silent = true }
  
  -- Toggle terminal with Ctrl+\
  vim.keymap.set('n', '<C-\\>', ':ToggleTerm<CR>', term_opts)
  vim.keymap.set('t', '<C-\\>', '<C-\\><C-n>:ToggleTerm<CR>', term_opts)
  
  -- Escape from terminal mode
  vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', term_opts)
  
  -- Window navigation from terminal mode
  vim.keymap.set('t', '<C-h>', '<C-\\><C-n><C-w>h', term_opts)
  vim.keymap.set('t', '<C-j>', '<C-\\><C-n><C-w>j', term_opts)
  vim.keymap.set('t', '<C-k>', '<C-\\><C-n><C-w>k', term_opts)
  vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-w>l', term_opts)
  
  -- Window navigation from normal mode
  vim.keymap.set('n', '<C-h>', '<C-w>h', term_opts)
  vim.keymap.set('n', '<C-j>', '<C-w>j', term_opts)
  vim.keymap.set('n', '<C-k>', '<C-w>k', term_opts)
  vim.keymap.set('n', '<C-l>', '<C-w>l', term_opts)
  
  -- Setup terminal multiplexer mappings for better WezTerm integration
  vim.keymap.set('n', '<leader>th', ':new<CR>:terminal<CR>', { desc = "New horizontal terminal" })
  vim.keymap.set('n', '<leader>tv', ':vnew<CR>:terminal<CR>', { desc = "New vertical terminal" })
  vim.keymap.set('n', '<leader>te', ':terminal<CR>', { desc = "Open terminal in current buffer" })
  
  -- Fix the bright red blocks by setting terminal highlight groups
  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
      -- Reset terminal highlight groups to avoid the red blocks
      vim.api.nvim_set_hl(0, "Visual", { bg = "#3b4261" }) -- More subtle visual selection
      vim.api.nvim_set_hl(0, "TermCursor", { bg = "#c0caf5" })
      vim.api.nvim_set_hl(0, "TermCursorNC", { bg = "#6b7089" })
    end,
  })
  
  -- Create commands for creating terminals with the current directory
  vim.api.nvim_create_user_command("Term", function()
    vim.cmd("new | term")
  end, { desc = "Open a terminal in a new horizontal split" })
  
  vim.api.nvim_create_user_command("VTerm", function()
    vim.cmd("vnew | term")
  end, { desc = "Open a terminal in a new vertical split" })
  
  vim.api.nvim_create_user_command("TTerm", function()
    vim.cmd("tabnew | term")
  end, { desc = "Open a terminal in a new tab" })

  print("WezTerm integration configured")
end

return M
