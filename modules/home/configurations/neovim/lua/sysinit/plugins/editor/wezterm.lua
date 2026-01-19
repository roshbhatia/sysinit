-- wezterm.nvim - Smart navigation between Neovim and Wezterm
--
-- Provides seamless navigation:
-- - If at edge of Neovim splits → switch Wezterm panes
-- - If not at edge → switch Neovim splits
-- - Switching to specific Wezterm panes/tabs
-- - Executing Wezterm CLI commands from Neovim
--
-- Works with your existing Wezterm passthrough configuration.
-- See: https://github.com/willothy/wezterm.nvim

return {
  "willothy/wezterm.nvim",
  config = function()
    local wezterm = require("wezterm")

    -- Smart navigation function
    -- Tries to move within Neovim first, falls back to Wezterm if at edge
    local function smart_navigate(direction, nvim_key)
      return function()
        local current_win = vim.api.nvim_get_current_win()

        -- Try to navigate within Neovim
        vim.cmd("wincmd " .. nvim_key)

        -- If we're still in the same window, we hit an edge
        -- Switch to Wezterm pane instead
        if vim.api.nvim_get_current_win() == current_win then
          wezterm.switch_pane.direction(direction)
        end
      end
    end

    -- Navigation keybindings
    local map = vim.keymap.set
    local opts = { silent = true, noremap = true }

    -- Smart navigation: Neovim splits → Wezterm panes
    map("n", "<C-h>", smart_navigate("Left", "h"), vim.tbl_extend("force", opts, { desc = "Navigate left (smart)" }))

    map("n", "<C-j>", smart_navigate("Down", "j"), vim.tbl_extend("force", opts, { desc = "Navigate down (smart)" }))

    map("n", "<C-k>", smart_navigate("Up", "k"), vim.tbl_extend("force", opts, { desc = "Navigate up (smart)" }))

    map("n", "<C-l>", smart_navigate("Right", "l"), vim.tbl_extend("force", opts, { desc = "Navigate right (smart)" }))

    -- Additional helpers for direct Wezterm control
    -- Switch to specific pane by ID
    map("n", "<leader>wp", function()
      local pane_id = vim.fn.input("Wezterm Pane ID: ")
      if pane_id ~= "" then
        wezterm.switch_pane.id(tonumber(pane_id))
      end
    end, vim.tbl_extend("force", opts, { desc = "Wezterm: Switch to pane by ID" }))

    -- Switch to specific tab by index
    map("n", "<leader>wt", function()
      local tab_idx = vim.fn.input("Wezterm Tab Index: ")
      if tab_idx ~= "" then
        wezterm.switch_tab.index(tonumber(tab_idx))
      end
    end, vim.tbl_extend("force", opts, { desc = "Wezterm: Switch to tab by index" }))
  end,
}
