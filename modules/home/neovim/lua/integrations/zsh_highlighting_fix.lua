-- ZSH Terminal Highlighting Fix
-- This module specifically targets and fixes the bright red block highlighting issue in ZSH

local M = {}

M.setup = function()
  -- Check if we're using ZSH
  local function is_zsh()
    local shell = os.getenv("SHELL")
    return shell and (shell:match("zsh") ~= nil)
  end
  
  -- Only apply fixes if we're using ZSH
  if not is_zsh() then
    print("ZSH highlighting fix: Not using ZSH, skipping")
    return
  end
  
  -- Create autocommands to fix ZSH highlighting issues
  vim.api.nvim_create_augroup("ZshHighlightingFix", { clear = true })
  
  -- Fix the annoying red blocks in terminal output
  vim.api.nvim_create_autocmd({"TermOpen", "TermEnter", "BufEnter"}, {
    group = "ZshHighlightingFix", 
    pattern = "term://*",
    callback = function()
      -- Fix ZSH syntax highlighting
      -- Mainly targeting the bright red blocks
      vim.api.nvim_set_hl(0, "zshPrecommand", { fg = "#9ece6a", bg = "NONE" })
      vim.api.nvim_set_hl(0, "zshCommand", { fg = "#7aa2f7", bg = "NONE" })
      vim.api.nvim_set_hl(0, "zshDeref", { fg = "#7aa2f7", bg = "NONE" })
      vim.api.nvim_set_hl(0, "zshShortDeref", { fg = "#7aa2f7", bg = "NONE" })
      vim.api.nvim_set_hl(0, "zshSubst", { fg = "#bb9af7", bg = "NONE" })
      vim.api.nvim_set_hl(0, "zshSubstQuoted", { fg = "#bb9af7", bg = "NONE" })
      
      -- Fix for specific red blocks coming from ZSH syntax highlighting
      vim.api.nvim_set_hl(0, "zshOperError", { fg = "#c0caf5", bg = "NONE" })
      vim.api.nvim_set_hl(0, "zshParenError", { fg = "#c0caf5", bg = "NONE" })
      vim.api.nvim_set_hl(0, "zshBracketError", { fg = "#c0caf5", bg = "NONE" })
      vim.api.nvim_set_hl(0, "zshBraceError", { fg = "#c0caf5", bg = "NONE" })
      
      -- Fix remaining error highlighting
      vim.api.nvim_set_hl(0, "Error", { fg = "#f7768e", bg = "NONE", bold = true })
      vim.api.nvim_set_hl(0, "ErrorMsg", { fg = "#f7768e", bg = "NONE" })
      
      -- Fix diff highlights which can appear as red blocks in some terminals
      vim.api.nvim_set_hl(0, "DiffDelete", { fg = "#414868", bg = "NONE" })
      vim.api.nvim_set_hl(0, "DiffChange", { fg = "#394b70", bg = "NONE" })
      vim.api.nvim_set_hl(0, "DiffAdd", { fg = "#266d6a", bg = "NONE" })
      vim.api.nvim_set_hl(0, "DiffText", { fg = "#394b70", bg = "NONE", bold = true })
      
      -- Fix specific terminal selection highlights
      vim.api.nvim_set_hl(0, "TermCursor", { bg = "#c0caf5" })
      vim.api.nvim_set_hl(0, "TermCursorNC", { bg = "#6b7089" })
      
      -- Fix Visual mode which can show as bright red in some terminals
      vim.api.nvim_set_hl(0, "Visual", { bg = "#33467C" })
      vim.api.nvim_set_hl(0, "VisualNOS", { bg = "#33467C" })
      
      -- Make search highlighting less obtrusive in terminal
      vim.api.nvim_set_hl(0, "Search", { fg = "#1a1b26", bg = "#e0af68" })
      vim.api.nvim_set_hl(0, "IncSearch", { fg = "#1a1b26", bg = "#ff9e64" })
    end
  })
  
  -- Disable highlighting in terminal mode for cleaner output
  vim.api.nvim_create_autocmd("TermOpen", {
    group = "ZshHighlightingFix",
    pattern = "*",
    callback = function()
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.opt_local.cursorline = false
      vim.opt_local.cursorcolumn = false
      vim.opt_local.spell = false
      vim.opt_local.hlsearch = false
      vim.cmd("startinsert")
    end
  })
  
  -- Fix ZSH highlighting issues in .zshrc file itself
  vim.api.nvim_create_autocmd("BufRead", {
    group = "ZshHighlightingFix",
    pattern = "*.zsh,*.zshrc,zshrc",
    callback = function()
      -- Fix syntax highlighting in ZSH config files
      vim.api.nvim_set_hl(0, "zshOperError", { link = "Normal" })
      vim.api.nvim_set_hl(0, "zshParenError", { link = "Normal" })
      vim.api.nvim_set_hl(0, "zshBracketError", { link = "Normal" })
      vim.api.nvim_set_hl(0, "zshBraceError", { link = "Normal" })
    end
  })
  
  print("ZSH highlighting fix: Configured to remove annoying red blocks")
end

return M
