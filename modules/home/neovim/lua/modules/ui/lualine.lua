# sysinit.nvim.readme-url="https://raw.githubusercontent.com/nvim-lualine/lualine.nvim/master/README.md"

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
          lualine_c = { 'filename', function()
            -- Display current session name if auto-session is available
            local status_ok, auto_session_lib = pcall(require, "auto-session.lib")
            if not status_ok then
              return ""
            end
            
            local session_name = auto_session_lib.current_session_name(true)
            if session_name and session_name ~= "" then
              return "󱂬 " .. session_name
            else
              return ""
            end
          end },
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

return M
