# sysinit.nvim.readme-url="https://raw.githubusercontent.com/romgrk/barbar.nvim/master/README.md"

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
  local status, wk = pcall(require, "which-key")
  if status then
    wk.register({
      ["<A-,>"] = { "<cmd>BufferPrevious<CR>", "Previous Buffer" },
      ["<A-.>"] = { "<cmd>BufferNext<CR>", "Next Buffer" },
      
      ["<A-<>"] = { "<cmd>BufferMovePrevious<CR>", "Move Buffer Left" },
      ["<A->>"] = { "<cmd>BufferMoveNext<CR>", "Move Buffer Right" },
      
      ["<A-1>"] = { "<cmd>BufferGoto 1<CR>", "Buffer 1" },
      ["<A-2>"] = { "<cmd>BufferGoto 2<CR>", "Buffer 2" },
      ["<A-3>"] = { "<cmd>BufferGoto 3<CR>", "Buffer 3" },
      ["<A-4>"] = { "<cmd>BufferGoto 4<CR>", "Buffer 4" },
      ["<A-5>"] = { "<cmd>BufferGoto 5<CR>", "Buffer 5" },
      ["<A-6>"] = { "<cmd>BufferGoto 6<CR>", "Buffer 6" },
      ["<A-7>"] = { "<cmd>BufferGoto 7<CR>", "Buffer 7" },
      ["<A-8>"] = { "<cmd>BufferGoto 8<CR>", "Buffer 8" },
      ["<A-9>"] = { "<cmd>BufferGoto 9<CR>", "Buffer 9" },
      ["<A-0>"] = { "<cmd>BufferLast<CR>", "Last Buffer" },
      
      ["<A-p>"] = { "<cmd>BufferPin<CR>", "Pin/Unpin Buffer" },
      ["<A-c>"] = { "<cmd>BufferClose<CR>", "Close Buffer" },
      ["<C-p>"] = { "<cmd>BufferPick<CR>", "Pick Buffer" },
      
      ["<leader>b"] = {
        name = "📑 Buffer",
        b = { "<cmd>BufferOrderByBufferNumber<CR>", "Order by Buffer Number" },
        d = { "<cmd>BufferOrderByDirectory<CR>", "Order by Directory" },
        l = { "<cmd>BufferOrderByLanguage<CR>", "Order by Language" },
        n = { "<cmd>BufferOrderByName<CR>", "Order by Name" },
        w = { "<cmd>BufferOrderByWindowNumber<CR>", "Order by Window Number" },
        p = { "<cmd>BufferPin<CR>", "Pin/Unpin Buffer" },
        P = { "<cmd>BufferGotoPinned<CR>", "Go to Pinned Buffer" },
        U = { "<cmd>BufferGotoUnpinned<CR>", "Go to Unpinned Buffer" },
        c = { "<cmd>BufferClose<CR>", "Close Buffer" },
        r = { "<cmd>BufferRestore<CR>", "Restore Last Closed Buffer" },
        a = { "<cmd>BufferCloseAllButCurrent<CR>", "Close All But Current" },
        v = { "<cmd>BufferCloseAllButVisible<CR>", "Close All But Visible" },
        h = { "<cmd>BufferCloseBuffersLeft<CR>", "Close All to the Left" },
        l = { "<cmd>BufferCloseBuffersRight<CR>", "Close All to the Right" },
        A = { "<cmd>BufferCloseAllButPinned<CR>", "Close All But Pinned" },
        C = { "<cmd>BufferCloseAllButCurrentOrPinned<CR>", "Close All But Current/Pinned" },
      },
    })
  else
    -- Set up normal keymaps if which-key is not available
    local map = vim.api.nvim_set_keymap
    local opts = { noremap = true, silent = true }
    
    -- Move to previous/next
    map('n', '<A-,>', '<cmd>BufferPrevious<CR>', opts)
    map('n', '<A-.>', '<cmd>BufferNext<CR>', opts)
    
    -- Re-order to previous/next
    map('n', '<A-<>', '<cmd>BufferMovePrevious<CR>', opts)
    map('n', '<A->>', '<cmd>BufferMoveNext<CR>', opts)
    
    -- Goto buffer in position...
    map('n', '<A-1>', '<cmd>BufferGoto 1<CR>', opts)
    map('n', '<A-2>', '<cmd>BufferGoto 2<CR>', opts)
    map('n', '<A-3>', '<cmd>BufferGoto 3<CR>', opts)
    map('n', '<A-4>', '<cmd>BufferGoto 4<CR>', opts)
    map('n', '<A-5>', '<cmd>BufferGoto 5<CR>', opts)
    map('n', '<A-6>', '<cmd>BufferGoto 6<CR>', opts)
    map('n', '<A-7>', '<cmd>BufferGoto 7<CR>', opts)
    map('n', '<A-8>', '<cmd>BufferGoto 8<CR>', opts)
    map('n', '<A-9>', '<cmd>BufferGoto 9<CR>', opts)
    map('n', '<A-0>', '<cmd>BufferLast<CR>', opts)
    
    -- Pin/unpin buffer
    map('n', '<A-p>', '<cmd>BufferPin<CR>', opts)
    
    -- Close buffer
    map('n', '<A-c>', '<cmd>BufferClose<CR>', opts)
    
    -- Magic buffer-picking mode
    map('n', '<C-p>', '<cmd>BufferPick<CR>', opts)
  end
  
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
