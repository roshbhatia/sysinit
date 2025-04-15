local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 
      'nvim-tree/nvim-web-devicons',
      'lewis6991/gitsigns.nvim'
    },
    config = function()
      local diagnostics = {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        sections = { "error", "warn", "info", "hint" },
        symbols = { error = " ", warn = " ", info = " ", hint = " " },
        colored = true,
        update_in_insert = false,
        always_visible = false,
      }

      local diff = {
        "diff",
        colored = true,
        symbols = { added = " ", modified = " ", removed = " " },
        cond = function() return vim.fn.winwidth(0) > 80 end,
      }

      local filetype = {
        "filetype",
        icons_enabled = true,
      }

      local location = {
        "location",
        padding = 0,
      }

      local spaces = function()
        return "spaces: " .. vim.api.nvim_buf_get_option(0, "shiftwidth")
      end

      local mode = {
        "mode",
        icons_enabled = true,
        icon = nil,
        padding = { left = 1, right = 1 },
      }

      local branch = {
        "branch",
        icons_enabled = true,
        icon = "",
        colored = true,
      }

      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = { left = '', right = ''},
          section_separators = { left = '', right = ''},
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          }
        },
        sections = {
          lualine_a = { mode },
          lualine_b = { branch, diff },
          lualine_c = { 'filename' },
          lualine_x = { diagnostics, 'encoding', filetype, spaces },
          lualine_y = { location },
          lualine_z = { 'progress' }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {'filename'},
          lualine_x = {'location'},
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = { 'fugitive', 'nvim-tree', 'toggleterm', 'lazy' }
      }
    end
  }
}

function M.setup()
  local commander = require("commander")
  
  -- Register lualine commands with commander
  commander.add({
    {
      desc = "Toggle Statusline",
      cmd = function()
        local ls = vim.opt.laststatus:get()
        if ls == 0 then
          vim.opt.laststatus = 2
        elseif ls == 2 then
          vim.opt.laststatus = 0
        end
        vim.cmd("redrawstatus")
      end,
      keys = { "n", "<leader>ts" },
      cat = "UI"
    }
  })
  
  -- Register verification steps
  verify.register_verification("lualine", {
    {
      desc = "Statusline Display",
      command = "Check bottom of screen",
      expected = "Should show a lualine statusline with mode, file info, and other details"
    },
    {
      desc = "Toggle Statusline",
      command = "<leader>ts",
      expected = "Should toggle the statusline visibility"
    }
  })
end

return M
