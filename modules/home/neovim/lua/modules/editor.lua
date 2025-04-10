local M = {}

-- Define module dependencies
M.depends_on = { "keybindings", "layout" }

M.plugins = {
  -- File Explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v2.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    opts = {
      close_if_last_window = true,
      window = {
        position = "left",
        width = 30,
        mappings = {
          ["<space>"] = "none",
        },
      },
      filesystem = {
        follow_current_file = true,
        hijack_netrw_behavior = "open_current",
        use_libuv_file_watcher = true,
      },
      event_handlers = {
        {
          event = "neo_tree_window_after_open",
          handler = function(args)
            if args.position == "left" or args.position == "right" then
              vim.cmd("wincmd =")
            end
          end,
        },
        {
          event = "neo_tree_window_after_close",
          handler = function(args)
            if args.position == "left" or args.position == "right" then
              vim.cmd("wincmd =")
            end
          end,
        },
      },
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle Explorer" },
      { "<leader>ef", "<cmd>Neotree focus<CR>", desc = "Focus Explorer" },
    },
  },
  
  -- Modern alternative to oil.nvim
  {
    "echasnovski/mini.files",
    opts = {
      windows = {
        preview = true,
        width_focus = 30,
        width_preview = 30,
      },
      options = {
        use_as_default_explorer = false,
      },
    },
    keys = {
      { "<leader>fm", "<cmd>lua MiniFiles.open()<CR>", desc = "Mini Files" },
    },
  },
  
  -- Fuzzy Finder
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim", 
        build = "make",
      },
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
    },
    opts = function()
      local actions = require("telescope.actions")
      
      return {
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          path_display = { "truncate" },
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
          mappings = {
            i = {
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-c>"] = actions.close,
              ["<CR>"] = actions.select_default,
              ["<C-s>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
            },
            n = {
              ["<Esc>"] = actions.close,
              ["j"] = actions.move_selection_next,
              ["k"] = actions.move_selection_previous,
              ["q"] = actions.close,
              ["<CR>"] = actions.select_default,
              ["<C-s>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
            },
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          file_browser = {
            theme = "dropdown",
            hijack_netrw = true,
          },
        },
      }
    end,
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help Tags" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent Files" },
      { "<leader>fc", "<cmd>Telescope colorscheme<CR>", desc = "Colorschemes" },
      { "<leader>fs", "<cmd>Telescope grep_string<CR>", desc = "Find Current Word" },
      { "<leader>fd", "<cmd>Telescope file_browser<CR>", desc = "File Browser" },
    },
  },
  
  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      signcolumn = true,
      watch_gitdir = {
        interval = 1000,
        follow_files = true,
      },
      attach_to_untracked = true,
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 1000,
        ignore_whitespace = false,
      },
      sign_priority = 6,
      update_debounce = 100,
      max_file_length = 40000,
      preview_config = {
        border = "rounded",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
      },
    },
    keys = {
      { "<leader>gg", "<cmd>Gitsigns toggle_signs<CR>", desc = "Toggle Gitsigns" },
      { "<leader>gh", "<cmd>Gitsigns preview_hunk<CR>", desc = "Preview Hunk" },
      { "<leader>gb", "<cmd>Gitsigns blame_line<CR>", desc = "Blame Line" },
      { "<leader>gd", "<cmd>Gitsigns diffthis<CR>", desc = "Diff This" },
      { "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", desc = "Reset Hunk" },
      { "]g", "<cmd>Gitsigns next_hunk<CR>", desc = "Next Hunk" },
      { "[g", "<cmd>Gitsigns prev_hunk<CR>", desc = "Previous Hunk" },
    },
  },
  
  -- Git commands
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gdiffsplit", "Gread", "Gwrite", "Gvdiffsplit" },
    keys = {
      { "<leader>gs", "<cmd>Git<CR>", desc = "Git Status" },
      { "<leader>gc", "<cmd>Git commit<CR>", desc = "Git Commit" },
      { "<leader>gp", "<cmd>Git push<CR>", desc = "Git Push" },
      { "<leader>gl", "<cmd>Git pull<CR>", desc = "Git Pull" },
    },
  },
  
  -- Search and replace
  {
    "nvim-pack/nvim-spectre",
    cmd = "Spectre",
    opts = {
      open_cmd = "noswapfile vnew",
      mapping = {
        ["toggle_line"] = {
          map = "dd",
          cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
          desc = "toggle current item",
        },
        ["enter_file"] = {
          map = "<cr>",
          cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
          desc = "goto current file",
        },
        ["send_to_qf"] = {
          map = "<leader>q",
          cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
          desc = "send all items to quickfix",
        },
        ["replace_cmd"] = {
          map = "<leader>c",
          cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
          desc = "input replace command",
        },
        ["run_replace"] = {
          map = "<leader>r",
          cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
          desc = "replace all",
        },
        ["change_view_mode"] = {
          map = "<leader>v",
          cmd = "<cmd>lua require('spectre').change_view()<CR>",
          desc = "change result view mode",
        },
      },
    },
    keys = {
      { "<leader>sr", function() require("spectre").open() end, desc = "Search and Replace" },
      { "<leader>sw", function() require("spectre").open_visual({select_word=true}) end, desc = "Search Current Word" },
      { "<leader>sf", function() require("spectre").open_file_search() end, desc = "Search in Current File" },
    },
  },
  
  -- Search motions
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      labels = "asdfghjklqwertyuiopzxcvbnm",
      search = {
        mode = "fuzzy",
      },
      jump = {
        autojump = true,
      },
      label = {
        uppercase = false,
        rainbow = {
          enabled = true,
        },
      },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash Remote" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash Treesitter Search" },
    },
  },
  
  -- Better window splits
  {
    "mrjones2014/smart-splits.nvim",
    opts = {
      ignored_filetypes = { "nofile", "quickfix", "prompt" },
      ignored_buftypes = { "NvimTree" },
      default_amount = 3,
      at_edge = "wrap",
      move_cursor_same_row = false,
      cursor_follows_swapped_bufs = false,
      resize_mode = {
        quit_key = "<ESC>",
        resize_keys = { "h", "j", "k", "l" },
        silent = true,
      },
    },
    keys = {
      -- Window navigation
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Move to left split" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Move to below split" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Move to above split" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move to right split" },
      
      -- Resizing
      { "<M-h>", function() require("smart-splits").resize_left() end, desc = "Resize left" },
      { "<M-j>", function() require("smart-splits").resize_down() end, desc = "Resize down" },
      { "<M-k>", function() require("smart-splits").resize_up() end, desc = "Resize up" },
      { "<M-l>", function() require("smart-splits").resize_right() end, desc = "Resize right" },
      
      -- Swapping buffers
      { "<leader>wh", function() require("smart-splits").swap_buf_left() end, desc = "Swap left" },
      { "<leader>wj", function() require("smart-splits").swap_buf_down() end, desc = "Swap down" },
      { "<leader>wk", function() require("smart-splits").swap_buf_up() end, desc = "Swap up" },
      { "<leader>wl", function() require("smart-splits").swap_buf_right() end, desc = "Swap right" },
    },
  },
  
  -- Buffer management
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        mode = "buffers",
        numbers = "none",
        close_command = function(bufnr) require("mini.bufremove").delete(bufnr, false) end,
        right_mouse_command = function(bufnr) require("mini.bufremove").delete(bufnr, false) end,
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(_, _, diag)
          local icons = {
            Error = " ",
            Warn = " ",
            Hint = " ",
            Info = " ",
          }
          local ret = (diag.error and icons.Error .. diag.error .. " " or "")
            .. (diag.warning and icons.Warn .. diag.warning or "")
          return vim.trim(ret)
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            highlight = "Directory",
            text_align = "left",
          },
        },
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        separator_style = "thin",
        always_show_bufferline = false,
        sort_by = "insert_after_current",
      },
    },
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
      { "<leader>bc", "<Cmd>BufferLinePickClose<CR>", desc = "Close buffer" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    },
  },
  
  -- Mini buffer remove
  {
    "echasnovski/mini.bufremove",
    keys = {
      { "<leader>bd", function() require("mini.bufremove").delete(0, false) end, desc = "Delete Buffer" },
      { "<leader>bD", function() require("mini.bufremove").delete(0, true) end, desc = "Delete Buffer (Force)" },
    },
  },
  
  -- Session management
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
      options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals" },
      pre_save = nil,
    },
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },
}

-- Register test cases
local test = require("core.test")
test.register_test("editor", function()
  local tests = {
    function()
      print("Testing file explorer...")
      local has_neotree = pcall(require, "neo-tree")
      assert(has_neotree, "neo-tree plugin should be available")
      return true, "File explorer is available"
    end,
    
    function()
      print("Testing mini.files...")
      local has_mini_files = pcall(require, "mini.files")
      assert(has_mini_files, "mini.files plugin should be available")
      return true, "mini.files is available"
    end,
    
    function()
      print("Testing telescope...")
      local has_telescope = pcall(require, "telescope")
      assert(has_telescope, "telescope plugin should be available")
      return true, "Telescope is available"
    end,
    
    function()
      print("Testing gitsigns...")
      local has_gitsigns = pcall(require, "gitsigns")
      assert(has_gitsigns, "gitsigns plugin should be available")
      return true, "Git integration is available"
    end,
  }
  
  for i, test_fn in ipairs(tests) do
    local success, msg = pcall(test_fn)
    if not success then
      return false, "Test " .. i .. " failed: " .. msg
    end
  end
  
  return true, "All editor tests passed"
end)

-- Add verification steps
local verify = require("core.verify")
verify.register_verification("editor", {
  {
    desc = "Check file explorer",
    command = "<leader>e",
    expected = "Should toggle Neo-tree file explorer",
  },
  {
    desc = "Test file finder",
    command = "<leader>ff",
    expected = "Should open Telescope find files",
  },
  {
    desc = "Test text search",
    command = "<leader>fg",
    expected = "Should open Telescope live grep for searching text",
  },
  {
    desc = "Test buffer switching",
    command = "<S-h> and <S-l>",
    expected = "Should cycle through open buffers",
  },
  {
    desc = "Test git integration",
    command = "<leader>gs",
    expected = "Should open Git status view with Fugitive",
  },
  {
    desc = "Test search and replace",
    command = "<leader>sr",
    expected = "Should open Spectre for search and replace",
  },
  {
    desc = "Test window navigation",
    command = "<C-h>, <C-j>, <C-k>, <C-l>",
    expected = "Should navigate between window splits",
  },
})

function M.setup()
  -- Register with layout system
  local core = require("core")
  local layout = core.get_module("layout")
  if layout and layout.register_panel then
    layout.register_panel("explorer", {
      open_cmd = "Neotree toggle",
      position = "left",
      size = 30,
      icon = "󰙅",
      title = "Explorer",
    })
  end
  
  -- Setup extensions for Telescope
  vim.api.nvim_create_autocmd("User", {
    pattern = "TelescopeLoaded",
    callback = function()
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("ui-select")
      require("telescope").load_extension("file_browser")
    end,
  })
  
  -- Setup tab and space rendering (optional but nice)
  vim.opt.list = true
  vim.opt.listchars = {
    tab = "→ ",
    trail = "·",
    nbsp = "␣",
  }
  
  -- Set up indent settings
  vim.opt.expandtab = true
  vim.opt.shiftwidth = 2
  vim.opt.tabstop = 2
  vim.opt.smartindent = true
  
  -- Set up search settings
  vim.opt.ignorecase = true
  vim.opt.smartcase = true
  vim.opt.inccommand = "split"
  
  -- Set up completion settings
  vim.opt.completeopt = "menu,menuone,noselect"
  
  -- Setup backups
  vim.opt.backup = false
  vim.opt.writebackup = false
  vim.opt.swapfile = false
  
  -- Misc settings
  vim.opt.scrolloff = 5
  vim.opt.sidescrolloff = 5
  vim.opt.splitright = true
  vim.opt.splitbelow = true
  
  -- Set up persistent undo
  vim.opt.undofile = true
  vim.opt.undodir = vim.fn.stdpath("state") .. "/undodir"
  
  -- Configure different behavior for specific file types
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "lua", "json", "yaml", "markdown" },
    callback = function()
      vim.opt_local.shiftwidth = 2
      vim.opt_local.tabstop = 2
    end,
  })
  
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "python", "rust", "go" },
    callback = function()
      vim.opt_local.shiftwidth = 4
      vim.opt_local.tabstop = 4
    end,
  })
  
  -- Notify system of setup completion
  local state = require("core.state")
  state.emit("editor.setup_complete", {})
end

require("core").register("editor", M)

return M