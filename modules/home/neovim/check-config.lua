-- Add stubs for potentially missing modules
local preload_ok, preload_msg = pcall(function()
  -- Create stub modules for common dependencies
  local stub_modules = {
    'nvim_comment', 'Comment', 'kubectl', 'symbols-outline', 'aerial',
    'formatter', 'nvim-treesitter', 'nvim-autopairs', 'trouble',
    'toggleterm', 'todo-comments', 'gitblame', 'lspkind', 'telescope'
  }
  
  for _, mod_name in ipairs(stub_modules) do
    package.preload[mod_name] = function() return {} end
  end
  
  -- Log issue identifiers
  print('Preloaded stub modules to help with loading')
end)

-- Now try to load the config module
local config_ok, config_msg = pcall(require, 'config')
if not config_ok then
  print('Error loading config module: ' .. config_msg)
  
  -- Try to identify which individual modules work
  for _, module in ipairs({'general', 'barline', 'startify', 'nvim-tree', 'codewindow', 'wilder', 'keystroke'}) do
    local mod_ok, mod_msg = pcall(require, 'config.' .. module)
    if not mod_ok then
      print('Error in module config.' .. module .. ': ' .. mod_msg)
    else
      print('Module config.' .. module .. ' loaded successfully')
    end
  end
  
  vim.cmd('cq')  -- Exit with error code
else
  print('Config module loaded successfully')
  vim.cmd('q')   -- Exit with success code
end