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
          x = { name = '󰆍 Terminal' },
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
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"),
      options = { "buffers", "curdir", "tabpages", "winsize", "globals" },
    },
    keys = {
      { "<leader>ss", function() require("persistence").load() end, desc = "Load Session" },
      { "<leader>sl", function() require("persistence").load({ last = true }) end, desc = "Load Last Session" },
      { "<leader>sd", function() require("persistence").stop() end, desc = "Stop Session Save" },
    },
  },
  
  -- Import other plugin modules
  require("plugins.ui"),
  require("plugins.editor"),
  require("plugins.lsp"),
  require("plugins.coding"),
  require("plugins.tools"),
}