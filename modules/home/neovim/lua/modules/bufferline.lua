local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "akinsho/bufferline.nvim",
    lazy = false,
    dependencies = { 
      "nvim-tree/nvim-web-devicons",
      "mrjones2014/legendary.nvim"
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
  local legendary = require("legendary")

  -- Which-key bindings using V3 format
  wk.add({
    { "<leader>b", group = "Buffer" },
    { "<leader>bn", "<cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
    { "<leader>bp", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer" },
    { "<leader>bc", "<cmd>BufferLinePickClose<CR>", desc = "Close selected buffer" },
    { "<leader>bb", "<cmd>BufferLinePick<CR>", desc = "Pick buffer" },
    { "<leader>bs", "<cmd>BufferLineSortByDirectory<CR>", desc = "Sort buffers by directory" }
  })

  -- Command Palette Commands
  local command_palette_commands = {
    {
      "BufferLineCycleNext",
      description = "Bufferline: Next buffer",
      category = "Bufferline"
    },
    {
      "BufferLineCyclePrev",
      description = "Bufferline: Previous buffer",
      category = "Bufferline"
    },
    {
      "BufferLinePick",
      description = "Bufferline: Pick buffer",
      category = "Bufferline"
    },
    {
      "BufferLinePickClose",
      description = "Bufferline: Close selected buffer",
      category = "Bufferline"
    },
    {
      "BufferLineSortByDirectory",
      description = "Bufferline: Sort buffers by directory",
      category = "Bufferline"
    }
  }

  -- Register with Legendary
  legendary.keymaps(which_key_bindings)
  legendary.commands(command_palette_commands)

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
      desc = "Legendary Keybindings",
      command = "Which-key <leader>b",
      expected = "Should show Bufferline commands"
    },
    {
      desc = "Command Palette Bufferline Commands",
      command = ":Legendary commands",
      expected = "Should show Bufferline commands in Command Palette"
    }
  })
end

return M