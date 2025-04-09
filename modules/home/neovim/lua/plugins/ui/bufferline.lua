-- Bufferline for better tab/buffer navigation
return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "moll/vim-bbye", -- For better buffer closing
  },
  keys = {
    { "<leader>bp", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
    { "<leader>bn", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    { "<leader>bc", "<cmd>Bdelete<cr>", desc = "Close buffer" },
    { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Close other buffers" },
    { "<leader>br", "<cmd>BufferLineCloseRight<cr>", desc = "Close buffers to the right" },
    { "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", desc = "Close buffers to the left" },
    { "<leader>bs", "<cmd>BufferLinePick<cr>", desc = "Pick buffer" },
    { "<leader>bso", "<cmd>BufferLineSortByDirectory<cr>", desc = "Sort by directory" },
    { "<leader>bse", "<cmd>BufferLineSortByExtension<cr>", desc = "Sort by extension" },
  },
  opts = {
    options = {
      mode = "buffers",
      numbers = "none",
      close_command = "Bdelete! %d",
      right_mouse_command = "Bdelete! %d",
      left_mouse_command = "buffer %d",
      middle_mouse_command = nil,
      indicator = {
        icon = "▎",
        style = "icon",
      },
      buffer_close_icon = "󰅖",
      modified_icon = "●",
      close_icon = "",
      left_trunc_marker = "",
      right_trunc_marker = "",
      max_name_length = 30,
      max_prefix_length = 30,
      tab_size = 21,
      diagnostics = "nvim_lsp",
      diagnostics_update_in_insert = false,
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
      offsets = {
        {
          filetype = "CHADTree",
          text = "File Explorer",
          text_align = "left",
          separator = true,
        },
      },
      show_buffer_icons = true,
      show_buffer_close_icons = true,
      show_close_icon = true,
      show_tab_indicators = true,
      persist_buffer_sort = true,
      separator_style = "thin",
      enforce_regular_tabs = true,
      always_show_bufferline = true,
      hover = {
        enabled = true,
        delay = 200,
        reveal = { "close" },
      },
      sort_by = "insert_after_current",
    },
    highlights = {
      buffer_selected = {
        bold = true,
        italic = false,
      },
    },
  },
  config = function(_, opts)
    require("bufferline").setup(opts)
    
    -- Integration with smart-splits
    local bufferline = require("bufferline")
    local smart_splits = require("smart-splits")
    
    -- Key to cycle through buffers with Tab
    vim.keymap.set('n', '<Tab>', function()
      bufferline.cycle(1)
    end, { desc = "Next buffer" })
    
    vim.keymap.set('n', '<S-Tab>', function()
      bufferline.cycle(-1)
    end, { desc = "Previous buffer" })
    
    -- Integrate with smart-splits for swapping buffers 
    vim.keymap.set('n', '<A-h>', function()
      smart_splits.swap_buf_left()
      bufferline.sort_by_tabs()
    end, { desc = "Swap buffer left" })
    
    vim.keymap.set('n', '<A-l>', function()
      smart_splits.swap_buf_right()
      bufferline.sort_by_tabs()
    end, { desc = "Swap buffer right" })
  end,
}