local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "akinsho/bufferline.nvim",
    lazy = false,
    dependencies = { 
      "nvim-tree/nvim-web-devicons"
    },
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          numbers = "none",
          close_command = "bdelete! %d",
          right_mouse_command = "bdelete! %d",
          left_mouse_command = "buffer %d",
          middle_mouse_command = nil,
          indicator = {
            icon = "▎",
            style = "icon"
          },
          buffer_close_icon = "",
          modified_icon = "●",
          close_icon = "",
          left_trunc_marker = "",
          right_trunc_marker = "",
          max_name_length = 20,
          max_prefix_length = 15,
          tab_size = 20,
          diagnostics = "nvim_lsp",
          diagnostics_update_in_insert = false,
          diagnostics_indicator = function(count, level)
            local icon = level:match("error") and " " 
                       or level:match("warning") and " "
                       or " "
            return " " .. icon .. count
          end,
          offsets = {
            {
              filetype = "oil",
              text = "File Explorer",
              text_align = "center",
              highlight = "Directory",
              separator = true
            }
          },
          show_buffer_icons = true,
          show_buffer_close_icons = true,
          show_close_icon = true,
          show_tab_indicators = true,
          persist_buffer_sort = true,
          separator_style = "thin",
          enforce_regular_tabs = false,
          always_show_bufferline = true,
          sort_by = "id",
        }
      })
    end
  }
}

function M.setup()
  local commander = require("commander")
  
  -- Register bufferline commands with commander
  commander.add({
    {
      desc = "Next Buffer",
      cmd = "<cmd>BufferLineCycleNext<CR>",
      keys = { "n", "<leader>bn" },
      cat = "Buffer"
    },
    {
      desc = "Previous Buffer",
      cmd = "<cmd>BufferLineCyclePrev<CR>",
      keys = { "n", "<leader>bp" },
      cat = "Buffer"
    },
    {
      desc = "Close Selected Buffer",
      cmd = "<cmd>BufferLinePickClose<CR>",
      keys = { "n", "<leader>bc" },
      cat = "Buffer"
    },
    {
      desc = "Pick Buffer",
      cmd = "<cmd>BufferLinePick<CR>",
      keys = { "n", "<leader>bb" },
      cat = "Buffer"
    },
    {
      desc = "Sort Buffers by Directory",
      cmd = "<cmd>BufferLineSortByDirectory<CR>",
      keys = { "n", "<leader>bs" },
      cat = "Buffer"
    }
  })

  -- Register verification steps
  verify.register_verification("bufferline", {
    {
      desc = "Bufferline Display",
      command = "Check top of screen",
      expected = "Should show buffer tabs at top of window"
    },
    {
      desc = "Next Buffer Command",
      command = ":BufferLineCycleNext",
      expected = "Should cycle to next buffer"
    },
    {
      desc = "Commander Keybindings",
      command = "<leader>bn",
      expected = "Should cycle to next buffer"
    },
    {
      desc = "Commander Commands",
      command = ":Telescope commander filter cat=Buffer",
      expected = "Should show Bufferline commands in Commander palette"
    }
  })
end

return M