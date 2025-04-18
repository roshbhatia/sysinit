-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/github/copilot.vim/master/doc/copilot.txt"
local M = {}

M.plugins = {
  {
    "github/copilot.vim",
    lazy = false,
    config = function()
      -- Basic settings
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_tab_fallback = ""
      
      -- Enable for specific filetypes
      vim.g.copilot_filetypes = {
        ["*"] = true,
        ["markdown"] = true,
        ["yaml"] = true,
        ["help"] = false,
        ["gitcommit"] = false,
        ["gitrebase"] = false,
        ["hgcommit"] = false,
        ["svn"] = false,
        ["cvs"] = false,
      }
      
      -- Custom mappings
      vim.keymap.set("i", "<C-j>", 'copilot#Accept("<CR>")', {
        expr = true,
        silent = true,
        replace_keycodes = false,
      })
      vim.keymap.set("i", "<C-k>", '<Plug>(copilot-previous)')
      vim.keymap.set("i", "<C-l>", '<Plug>(copilot-next)')
      vim.keymap.set("i", "<C-\\>", '<Plug>(copilot-dismiss)')
      
      -- Create toggle function
      local function toggle_copilot()
        if vim.g.copilot_enabled == 0 then
          vim.cmd("Copilot enable")
          vim.notify("Copilot enabled", vim.log.levels.INFO)
        else
          vim.cmd("Copilot disable")
          vim.notify("Copilot disabled", vim.log.levels.INFO)
        end
      end
      
      -- Register with which-key
      local wk = require("which-key")
      wk.add({
        { "<leader>a", group = "AI", icon = { icon = "󰚩", hl = "WhichKeyIconGreen" } },
        { "<leader>at", toggle_copilot, desc = "Toggle Copilot", mode = "n" },
        { "<leader>as", "<cmd>Copilot status<CR>", desc = "Copilot Status", mode = "n" },
        { "<leader>ap", "<cmd>Copilot panel<CR>", desc = "Copilot Panel", mode = "n" },
      })
      
      -- Highlight copilot suggestions with a more subtle color
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          vim.api.nvim_set_hl(0, "CopilotSuggestion", {
            fg = "#888888",
            ctermfg = 8,
            force = true,
          })
        end,
      })
    end
  }
}

return M
