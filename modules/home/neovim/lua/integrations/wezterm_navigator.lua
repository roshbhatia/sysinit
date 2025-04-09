-- WezTerm & Neovim Navigation Utility
-- This module allows seamless navigation between WezTerm panes and Neovim splits
local M = {}

M.setup = function()
  -- Function to detect if we're in WezTerm
  local function is_wezterm()
    local term = os.getenv("TERM")
    local wezterm_env = os.getenv("WEZTERM_EXECUTABLE")
    return (term and term:match("wezterm")) or (wezterm_env ~= nil)
  end

  -- Detect if we're in a WezTerm environment
  local in_wezterm = is_wezterm()
  if not in_wezterm then
    print("WezTerm Navigator: Not running in WezTerm, integration disabled")
    return
  end

  -- Helper for sending WezTerm navigation commands
  local function navigate_wezterm(direction)
    local cmds = {
      left = "ActivatePaneDirection 'Left'",
      right = "ActivatePaneDirection 'Right'",
      up = "ActivatePaneDirection 'Up'",
      down = "ActivatePaneDirection 'Down'"
    }
    local cmd = cmds[direction]
    if cmd then
      io.write(string.format("\x1b]1337;%s\x07", cmd))
    end
  end

  -- Helper for navigating Neovim windows
  local function navigate_neovim(direction)
    local cmds = {
      left = "wincmd h",
      right = "wincmd l",
      up = "wincmd k",
      down = "wincmd j"
    }
    local cmd = cmds[direction]
    if cmd then
      vim.cmd(cmd)
    end
  end

  -- Main navigation function that handles both Neovim and WezTerm
  local function smart_navigate(direction)
    -- Get current window count
    local win_count = vim.fn.winnr('$')
    
    -- Get current cursor position
    local current_win = vim.fn.winnr()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local win_height = vim.fn.winheight(0)
    local win_width = vim.fn.winwidth(0)
    
    -- Navigate in Neovim first
    local prev_win = current_win
    navigate_neovim(direction)
    local new_win = vim.fn.winnr()
    
    -- If we didn't change windows in Neovim, try navigating in WezTerm
    if new_win == prev_win then
      -- Check if we're at an edge
      local at_edge = false
      if direction == "left" and col <= 1 then
        at_edge = true
      elseif direction == "right" and col >= win_width - 2 then
        at_edge = true
      elseif direction == "up" and row <= 1 then
        at_edge = true
      elseif direction == "down" and row >= win_height then
        at_edge = true
      end
      
      -- If we're at an edge, send command to WezTerm
      if at_edge then
        navigate_wezterm(direction)
      end
    end
  end
  
  -- Create keymaps for navigating using Alt+Arrows
  vim.keymap.set('n', '<A-Left>', function() smart_navigate('left') end, { desc = "Smart navigate left" })
  vim.keymap.set('n', '<A-Right>', function() smart_navigate('right') end, { desc = "Smart navigate right" })
  vim.keymap.set('n', '<A-Up>', function() smart_navigate('up') end, { desc = "Smart navigate up" })
  vim.keymap.set('n', '<A-Down>', function() smart_navigate('down') end, { desc = "Smart navigate down" })
  
  -- Also create terminal mode mappings
  vim.keymap.set('t', '<A-Left>', '<C-\\><C-n><cmd>lua require("integrations.wezterm_navigator").smart_navigate("left")<CR>', { desc = "Smart navigate left (terminal)" })
  vim.keymap.set('t', '<A-Right>', '<C-\\><C-n><cmd>lua require("integrations.wezterm_navigator").smart_navigate("right")<CR>', { desc = "Smart navigate right (terminal)" })
  vim.keymap.set('t', '<A-Up>', '<C-\\><C-n><cmd>lua require("integrations.wezterm_navigator").smart_navigate("up")<CR>', { desc = "Smart navigate up (terminal)" })
  vim.keymap.set('t', '<A-Down>', '<C-\\><C-n><cmd>lua require("integrations.wezterm_navigator").smart_navigate("down")<CR>', { desc = "Smart navigate down (terminal)" })
  
  print("WezTerm Navigator: Configured seamless navigation between WezTerm panes and Neovim windows")
  
  -- Expose the navigation function
  M.smart_navigate = smart_navigate
end

return M
