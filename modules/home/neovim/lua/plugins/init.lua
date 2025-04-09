-- Plugin management with lazy.nvim
-- Main plugin configuration entry point

return {
  -- Core plugins
  -- ============
  
  -- Lazy.nvim package manager
  {
    "folke/lazy.nvim",
  },
  
  -- Which-key for keybinding help
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local which_key = require("which-key")
      which_key.setup({
        plugins = {
          marks = true,
          registers = true,
          spelling = { enabled = false },
          presets = {
            operators = true,
            motions = true,
            text_objects = true,
            windows = true,
            nav = true,
            z = true,
            g = true,
          },
        },
        window = {
          border = "single",
          position = "bottom",
          margin = { 1, 0, 1, 0 },
          padding = { 2, 2, 2, 2 },
          winblend = 0,
        },
        layout = {
          height = { min = 4, max = 25 },
          width = { min = 20, max = 50 },
          spacing = 3,
          align = "left",
        },
        ignore_missing = false,
        hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "^:", "^ ", "^call ", "^lua " },
        show_help = true,
        triggers = "auto",
        triggers_blacklist = {
          i = { "j", "k" },
          v = { "j", "k" },
        },
      })
      
      -- Register key group labels
      which_key.register({
        ['<leader>'] = {
          f = { name = '󰈔 Find' },
          b = { name = '󰓩 Buffer' },
          w = { name = '󰖮 Window' },
          c = { name = '󰌵 Code/Copilot' },
          g = { name = ' Git' },
          t = { name = '󰙅 Toggle' },
          d = { name = ' Debug' },
          h = { name = '⚓ Harpoon' },
          m = { name = '󰍔 Markdown' },
          r = { name = '󰑕 Refactor' },
          s = { name = '󰑓 Session' },
          p = { name = '󰏗 Project' },
          y = { name = '󰒋 YAML' },
        },
      })
    end,
  },
  
  -- File Explorer with CHADTree
  {
    "ms-jpq/chadtree",
    branch = "chad",
    build = "python3 -m chadtree deps",
    cmd = { "CHADopen", "CHADdrop" },
    keys = {
      { "<leader>e", "<cmd>CHADopen<cr>", desc = "Open File Explorer" },
      { "<F2>", "<cmd>CHADopen<cr>", desc = "Open File Explorer" },
    },
    config = function()
      vim.g.chadtree_settings = {
        view = {
          width = 30,
          open_direction = "left",
        },
        theme = {
          icon_colour_set = "vscode",
          text_colour_set = "env",
        },
      }
    end,
  },
  
  -- Startify for start screen
  {
    "mhinz/vim-startify",
    lazy = false,
    priority = 100,
    config = function()
      vim.g.startify_session_dir = vim.fn.stdpath("data") .. "/sessions"
      vim.g.startify_session_autoload = 1
      vim.g.startify_session_persistence = 1
      vim.g.startify_session_delete_buffers = 1
      vim.g.startify_change_to_dir = 1
      vim.g.startify_fortune_use_unicode = 1
      vim.g.startify_files_number = 5
      vim.g.startify_padding_left = 3
      
      -- Custom header
      vim.g.startify_custom_header = {
        "⠀⠀⠀⠀⠀⠀⠐⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠈⣾⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⢸⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⣈⣼⣄⣠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠉⠑⢷⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⣼⣐⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠘⡚⢧⠀⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⢃⢿⡇⠀⠀⡾⡀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠸⣇⠀⠀⠡⣰⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠇⣿⠀⢠⣄⢿⠇⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⢸⡇⠜⣭⢸⡀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⣼⠀⡙⣿⣿⠰⢫⠁⣇⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⢰⣽⠱⡈⠋⠋⣤⡤⠳⠉⡆⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⡜⠡⠊⠑⠄⣠⣿⠃⠀⣣⠃⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠐⣼⡠⠥⠊⡂⣼⢀⣤⠠⡲⢂⡌⡄⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⣀⠝⡛⢁⡴⢉⠗⠛⢰⣶⣯⢠⠺⠀⠈⢥⠰⡀⠀⠀",
        "⠀⣠⣴⢿⣿⡟⠷⠶⣶⣵⣲⡀⣨⣿⣆⡬⠖⢛⣶⣼⡗⠈⠢⠀",
        "⢰⣹⠭⠽⢧⠅⢂⣳⠛⢿⡽⣿⢿⡿⢟⣟⡻⢾⣿⣿⡤⢴⣶⡃",
      }
      
      -- Custom startify lists
      vim.g.startify_lists = {
        { type = 'dir',        header = {'   Current Directory:'} },
        { type = 'sessions',   header = {'   Sessions'}           },
        { type = 'bookmarks',  header = {'   Bookmarks'}          },
        { type = 'commands',   header = {'   Commands'}           }
      }
      
      -- Startify bookmarks
      vim.g.startify_bookmarks = {
        { c = '~/.config/nvim/init.lua' },
        { z = '~/.zshrc' },
      }
      
      -- Startify commands
      vim.g.startify_commands = {
        { f = {'Find File', ':Telescope find_files'} },
        { g = {'Find Word', ':Telescope live_grep'} },
        { r = {'Recent Files', ':Telescope oldfiles'} },
        { s = {'Load Session', ':Telescope sessions'} },
        { p = {'Projects', ':Telescope projects'} },
      }
    end,
  },
  
  -- Session Management
  {
    "rmagatti/auto-session",
    event = "VimEnter",
    cmd = { "SessionSave", "SessionRestore", "SessionDelete", "Autosession" },
    keys = {
      { "<leader>ss", "<cmd>SessionSave<CR>", desc = "Save Session" },
      { "<leader>sr", "<cmd>SessionRestore<CR>", desc = "Restore Session" },
      { "<leader>sd", "<cmd>SessionDelete<CR>", desc = "Delete Session" },
    },
    config = function()
      require("auto-session").setup({
        log_level = 'error',
        auto_session_enable_last_session = true,
        auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
        auto_session_enabled = true,
        auto_save_enabled = true,
        auto_restore_enabled = true,
        auto_session_use_git_branch = true,
        auto_session_suppress_dirs = nil,
        auto_session_allowed_dirs = nil,
        
        -- Customize session name
        pre_save_cmds = {
          function()
            -- Remove CHADTree before saving session
            pcall(function() 
              vim.cmd('CHADclose')
            end)
          end,
        },
        
        -- Session lens integration for telescope
        session_lens = {
          load_on_setup = true,
          theme_conf = { border = true },
          previewer = false,
        },
      })
      
      -- Use SessionSave explicitly to avoid conflicts
      vim.keymap.set("n", "<leader>sl", function()
        require("auto-session.session-lens").search_session()
      end, { desc = "Search Sessions" })
    end,
    dependencies = {
      { "rmagatti/session-lens", dependencies = { "nvim-telescope/telescope.nvim" } },
    },
  },
  
  -- Fast treesitter-based highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/nvim-treesitter-context",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "c", "cpp", "css", "go", "html", "java", "javascript", 
          "json", "lua", "markdown", "markdown_inline", "python", "regex", 
          "rust", "tsx", "typescript", "vim", "vimdoc", "yaml",
        },
        auto_install = true,
        highlight = { 
          enable = true,
          -- Disable on large files for performance
          disable = function(_, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
              ["]a"] = "@parameter.inner",
            },
            goto_next_end = {
              ["]F"] = "@function.outer",
              ["]C"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
              ["[a"] = "@parameter.inner",
            },
            goto_previous_end = {
              ["[F"] = "@function.outer",
              ["[C"] = "@class.outer",
            },
          },
        },
      })
      
      -- Setup treesitter context
      require("treesitter-context").setup({
        enable = true,
        max_lines = 3,
        min_window_height = 15,
        line_numbers = true,
        multiline_threshold = 5,
        trim_scope = 'outer',
        mode = 'cursor',
        on_attach = nil,
      })
    end,
  },
  
  -- Icons for various plugins
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    config = function()
      require("nvim-web-devicons").setup({
        override = {
          zsh = {
            icon = "",
            color = "#428850",
            name = "Zsh"
          },
          sh = {
            icon = "",
            color = "#1DC121",
            name = "Bash"
          },
          [".gitignore"] = {
            icon = "",
            color = "#f1502f",
            name = "GitIgnore"
          },
          [".gitattributes"] = {
            icon = "",
            color = "#f1502f",
            name = "GitAttributes"
          }
        },
        color_icons = true,
        default = true,
        strict = true,
      })
    end,
  },
  
  -- Enhanced UI with noice.nvim
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim", -- UI components
      "rcarriga/nvim-notify",  -- Notifications
    },
    opts = {
      lsp = {
        -- Override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        progress = {
          enabled = true,
          format = "lsp_progress",
          format_done = "lsp_progress_done",
          throttle = 1000 / 30, -- frequency to update lsp progress message
          view = "mini",
        },
        hover = { enabled = false }, -- We use Lspsaga for hover
        signature = { enabled = false }, -- We use Lspsaga for signature help
      },
      -- Use compact pop-up windows for cmdline and search
      cmdline = {
        enabled = true,
        view = "cmdline_popup",
        format = {
          cmdline = { pattern = "^:", icon = ":", lang = "vim" },
          search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
          search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
        },
      },
      messages = {
        enabled = true,
        view = "mini",
        view_error = "mini",
        view_warn = "mini",
        view_history = "messages",
        view_search = "virtualtext",
      },
      popupmenu = {
        enabled = true,
        backend = "nui",
      },
      redirect = {
        view = "mini",
        filter = { event = "msg_show" },
      },
      commands = {
        history = {
          view = "split",
          opts = { enter = true, format = "details" },
          filter = {
            any = {
              { event = "notify" },
              { error = true },
              { warning = true },
              { event = "msg_show", kind = { "" } },
              { event = "lsp", kind = "message" },
            },
          },
        },
        last = {
          view = "mini",
          opts = { enter = true, format = "details" },
          filter = {
            any = {
              { event = "notify" },
              { error = true },
              { warning = true },
              { event = "msg_show", kind = { "" } },
              { event = "lsp", kind = "message" },
            },
          },
          filter_opts = { count = 1 },
        },
      },
      views = {
        cmdline_popup = {
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          position = {
            row = 5,
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
          win_options = {
            winhighlight = { Normal = "NormalFloat", FloatBorder = "FloatBorder" },
          },
        },
        mini = {
          timeout = 3000,
          max_height = 20,
          max_width = 80,
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winblend = 0,
          },
        },
      },
      routes = {
        -- Hide useless written messages
        {
          filter = {
            event = "msg_show",
            kind = "",
            find = "written",
          },
          opts = { skip = true },
        },
        -- Clean up some command line messages
        {
          filter = {
            event = "msg_show",
            find = "%d+L, %d+B",
          },
          view = "mini",
        },
        -- Clean up search count
        {
          filter = {
            event = "msg_show",
            kind = "search_count",
          },
          opts = { skip = true },
        },
      },
      presets = {
        bottom_search = true,         -- use a classic bottom cmdline for search
        command_palette = true,       -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false,           -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false,       -- add a border to hover docs and signature help
      },
      -- Significantly improves performance
      throttle = 1000 / 120,
    },
    -- Additional keys for noice
    keys = {
      { "<leader>nl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
      { "<leader>nh", function() require("noice").cmd("history") end, desc = "Noice History" },
      { "<leader>nd", function() require("noice").cmd("dismiss") end, desc = "Dismiss Notifications" },
      { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, expr = true, desc = "Scroll forward", mode = {"i", "n", "s"} },
      { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, expr = true, desc = "Scroll backward", mode = {"i", "n", "s"} },
    },
  },
  
  -- Markdown Preview
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Toggle Markdown Preview" },
    },
    config = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_browser = ''
      vim.g.mkdp_echo_preview_url = 1
      vim.g.mkdp_page_title = '${name}'
    end,
  },
  
  -- Import other plugin modules
  require("plugins.ui"),
  require("plugins.editor"),
  require("plugins.lsp"),
  require("plugins.coding"),
  require("plugins.tools"),
  require("plugins.lazy-close"),
  require("plugins.indent"),
  require("plugins.which-key-fancy"),
  require("plugins.notifications"),  -- Re-enabled with toggle functionality
  require("plugins.alpha"),
  require("plugins.copilot"),
  require("plugins.diffview"),
  require("plugins.smart-splits"),
  require("plugins.telescope"),
}