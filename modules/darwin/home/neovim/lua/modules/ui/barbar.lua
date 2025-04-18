-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/romgrk/barbar.nvim/refs/heads/master/doc/barbar.txt"
local M = {}

M.plugins = {
  {
    "romgrk/barbar.nvim",
    dependencies = {
      "lewis6991/gitsigns.nvim", -- Optional: for git status
      "nvim-tree/nvim-web-devicons", -- Optional: for file icons
    },
    lazy = false,
    init = function() 
      vim.g.barbar_auto_setup = false 
    end,
    config = function()
      require("barbar").setup({
        -- Enable animations
        animation = true,
        
        -- Show tabpages indicator at the top right corner
        tabpages = true,
        
        -- Enable clickable tabs
        --  - left-click: go to buffer
        --  - middle-click: delete buffer
        clickable = true,
        
        -- Automatically hide the tabline when there are fewer buffers
        auto_hide = false,
        
        -- Hide file extensions and other details
        hide = {extensions = true, inactive = false},
        
        -- Enable highlighting visible buffers
        highlight_visible = true,
        
        -- Highlight alternate buffers
        highlight_alternate = true,
        
        -- Enable highlighting file icons in inactive buffers
        highlight_inactive_file_icons = true,
        
        -- Icons configuration
        icons = {
          -- Buffer index and number display
          buffer_index = false,
          buffer_number = false,
          
          -- Close button
          button = '',
          
          -- Add diagnostic icons
          diagnostics = {
            [vim.diagnostic.severity.ERROR] = {enabled = true, icon = ' '},
            [vim.diagnostic.severity.WARN] = {enabled = true, icon = ' '},
            [vim.diagnostic.severity.INFO] = {enabled = false},
            [vim.diagnostic.severity.HINT] = {enabled = false},
          },
          
          -- Git integration
          gitsigns = {
            added = {enabled = true, icon = '+'},
            changed = {enabled = true, icon = '~'},
            deleted = {enabled = true, icon = '-'},
          },
          
          -- File type icons
          filetype = {
            custom_colors = false,
            enabled = true,
          },
          
          -- Buffer separators
          separator = {left = '▎', right = ''},
          separator_at_end = true,
          
          -- Modified and pinned indicators
          modified = {button = '●'},
          pinned = {button = '', filename = true},
          
          -- Use the 'powerline' preset for a more modern look
          preset = 'powerline',
          
          -- Icons for different buffer states
          alternate = {filetype = {enabled = false}},
          current = {buffer_index = true},
          inactive = {button = '×'},
          visible = {modified = {buffer_number = false}},
        },
        
        -- Insert new buffers at the end
        insert_at_end = false,
        insert_at_start = false,
        
        -- Padding and max length
        maximum_padding = 1,
        minimum_padding = 1,
        maximum_length = 30,
        minimum_length = 0,
        
        -- Use semantic letters for buffer-pick mode
        semantic_letters = true,
        
        -- Support for sidebars and tree views
        sidebar_filetypes = {
          -- Default for NvimTree
          NvimTree = true,
          
          -- Explicitly provide options
          undotree = { text = 'undotree' },
          
          -- Handle neo-tree
          ['neo-tree'] = { event = 'BufWipeout' },
          
          -- Custom for Outline
          Outline = { event = 'BufWinLeave', text = 'symbols-outline' },
        },
        
        -- Letters used for buffer-pick mode
        letters = 'asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP',
        
        -- Case-insensitive sorting
        sort = {
          ignore_case = true,
        },
        
        -- Focus previous buffer when closing the current
        focus_on_close = 'left',
      })
    end
  }
}

function M.setup()
  -- Register keymaps with which-key if available
  local wk = pcall(require, "which-key")
  wk.add({
    { "<leader>b", group = "📑 Buffer", icon = { icon = "📑" } },
    { "<leader>bc", "<cmd>BufferClose<CR>", desc = "Close Buffer" },
    { "<leader>ba", "<cmd>BufferCloseAllButCurrent<CR>", desc = "Close All But Current" },
    { "<leader>bv", "<cmd>BufferCloseAllButVisible<CR>", desc = "Close All But Visible" },
    { "<leader>b,", "<cmd>BufferPrevious<CR>", desc = "Previous Buffer" },
    { "<leader>b.", "<cmd>BufferNext<CR>", desc = "Next Buffer" },
    { "<leader>b<", "<cmd>BufferMovePrevious<CR>", desc = "Move Buffer Left" },
    { "<leader>b>", "<cmd>BufferMoveNext<CR>", desc = "Move Buffer Right" },
  })

  -- Enable mouse for barbar (optional)
  vim.opt.mouse = "a"
  
  -- Set up session support for barbar
  vim.opt.sessionoptions:append("globals")
  vim.api.nvim_create_autocmd("User", {
    pattern = "SessionSavePre",
    callback = function()
      vim.cmd("silent! BarbarSave")
    end
  })
  
  -- Configure the experimental popup menu palette as requested
  -- This will make Command Palette style popup appear in the middle of the screen
  local wilder_status, wilder = pcall(require, "wilder")
  if wilder_status then
    wilder.set_option('renderer', wilder.popupmenu_renderer(
      wilder.popupmenu_palette_theme({
        -- 'single', 'double', 'rounded' or 'solid'
        border = 'rounded',
        max_height = '75%',      -- max height of the palette
        min_height = 0,          -- set to the same as 'max_height' for a fixed height window
        prompt_position = 'top', -- 'top' or 'bottom' to set the location of the prompt
        reverse = 0,             -- set to 1 to reverse the order of the list
      })
    ))
  end
end

return M
