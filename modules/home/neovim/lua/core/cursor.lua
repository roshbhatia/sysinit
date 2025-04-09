-- Enhanced cursor configuration with visual mode distinction
local M = {}

M.setup = function()
  -- Set different cursor shapes for different modes with animation
  -- The key is to use Nvim's guicursor option with blinking
  vim.opt.guicursor = "n-c:block-Cursor/lCursor-blinkwait300-blinkoff200-blinkon200,"
                   .. "i-ci:ver25-Cursor/lCursor-blinkwait300-blinkoff200-blinkon200,"
                   .. "v-ve:block-Cursor/lCursor-blinkwait300-blinkoff200-blinkon200,"
                   .. "r-cr:hor20-Cursor/lCursor-blinkwait300-blinkoff200-blinkon200,"
                   .. "a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor"

  -- Set underline cursor in normal mode by modifying the Cursor highlight group
  vim.api.nvim_create_autocmd({"ColorScheme", "VimEnter"}, {
    callback = function()
      -- In normal mode, we'll use an underline cursor (override the block setting above)
      vim.api.nvim_set_hl(0, "Cursor", { underline = true, bold = true })
      
      -- In visual mode, use a custom highlight for the cursor
      vim.api.nvim_set_hl(0, "VisualCursor", { bg = "#ff5555", fg = "#f8f8f2" })
      
      -- In insert mode, use a thin vertical bar cursor
      vim.api.nvim_set_hl(0, "InsertCursor", { bg = "#50fa7b", fg = "#282a36" })
      
      -- Define command to toggle cursor blink
      vim.api.nvim_create_user_command("ToggleCursorBlink", function()
        if vim.opt.guicursor:get():find("blinkon") then
          vim.opt.guicursor = vim.opt.guicursor:get():gsub("blinkon%d+", "blinkon0")
          print("Cursor blinking disabled")
        else
          -- Restore the original blinking settings
          vim.opt.guicursor = "n-c:block-Cursor/lCursor-blinkwait300-blinkoff200-blinkon200,"
                           .. "i-ci:ver25-Cursor/lCursor-blinkwait300-blinkoff200-blinkon200,"
                           .. "v-ve:block-Cursor/lCursor-blinkwait300-blinkoff200-blinkon200,"
                           .. "r-cr:hor20-Cursor/lCursor-blinkwait300-blinkoff200-blinkon200,"
                           .. "a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor"
          print("Cursor blinking enabled")
        end
      end, {})
      
      -- Add the toggle to which-key if available
      local wk_ok, wk = pcall(require, "which-key")
      if wk_ok then
        wk.register({
          ["<leader>tc"] = { "<cmd>ToggleCursorBlink<CR>", "Toggle cursor blink" },
        })
      end
    end,
    group = vim.api.nvim_create_augroup("CustomCursor", { clear = true }),
  })

  -- Override the cursor handling for specific environments
  if os.getenv("TERM") == "wezterm" then
    -- Add specific cursor customization for WezTerm
    -- since it has better cursor control
    vim.api.nvim_create_autocmd("ModeChanged", {
      callback = function()
        local current_mode = vim.api.nvim_get_mode().mode
        if current_mode == 'n' then
          vim.opt.guicursor = "n-c:underline-Cursor/lCursor-blinkwait300-blinkoff200-blinkon200"
        elseif current_mode == 'i' or current_mode == 'c' then
          vim.opt.guicursor = "i-ci:ver25-InsertCursor/lCursor-blinkwait300-blinkoff200-blinkon200"
        elseif current_mode:find('v') or current_mode:find('V') then
          vim.opt.guicursor = "v-ve:block-VisualCursor/lCursor-blinkwait300-blinkoff200-blinkon200"
        end
      end,
      group = vim.api.nvim_create_augroup("WezTermCursor", { clear = true }),
    })
  end

  print("Enhanced cursor configuration loaded")
end

return M
