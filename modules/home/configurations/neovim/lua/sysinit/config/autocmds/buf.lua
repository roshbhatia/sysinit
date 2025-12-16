local M = {}

local function disable_ui_elements(win)
  local ok, config = pcall(vim.api.nvim_win_get_config, win)
  if not ok then
    return
  end

  local buf = vim.api.nvim_win_get_buf(win)
  local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })

  local special_filetypes = {
    "help",
    "oil",
    "oil_preview",
    "opencode",
    "quickfix",
    "neogit",
    "NeogitStatus",
    "NeogitCommitView",
    "NeogitPopup",
    "NeogitPreview",
  }

  local should_disable = config.relative ~= "" or vim.tbl_contains(special_filetypes, ft)

  if should_disable then
    pcall(function()
      vim.wo[win].foldcolumn = "0"
      vim.wo[win].signcolumn = "no"
    end)
  else
    pcall(function()
      vim.wo[win].foldcolumn = "1"
      vim.wo[win].signcolumn = "auto"
    end)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd({ "WinEnter", "WinNew" }, {
    callback = function()
      disable_ui_elements(vim.api.nvim_get_current_win())
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "OilEnter",
    callback = function()
      local wins = vim.api.nvim_list_wins()
      for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
        local config = vim.api.nvim_win_get_config(win)

        if ft == "oil" or config.relative ~= "" then
          vim.wo[win].foldcolumn = "0"
          vim.wo[win].signcolumn = "no"
        end
      end
    end,
  })
end

return M
