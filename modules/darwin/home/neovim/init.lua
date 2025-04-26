local function setup_package_manager()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)

  local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
  local lua_dir = init_dir .. "/lua"
  vim.opt.rtp:prepend(lua_dir)
end

local function setup_leader()
  vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { noremap = true, silent = true })
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "
  vim.keymap.set("n", ":", ":", { noremap = true, desc = "Command mode" })
end

local function setup_common_settings()
  vim.opt.hlsearch = true
  vim.opt.incsearch = true
  vim.opt.ignorecase = true
  vim.opt.smartcase = true

  vim.opt.expandtab = true
  vim.opt.shiftwidth = 2
  vim.opt.tabstop = 2
  vim.opt.smartindent = true
  vim.opt.wrap = false
  vim.opt.linebreak = true
  vim.opt.breakindent = true

  vim.opt.splitbelow = true
  vim.opt.splitright = true

  vim.opt.updatetime = 100
  vim.opt.timeoutlen = 300
  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8
  vim.opt.mouse = "a"
  vim.opt.clipboard = "unnamedplus"
end

local function setup_neovim_settings()
  vim.opt.number = true
  vim.opt.cursorline = true
  vim.opt.signcolumn = "yes"
  vim.opt.termguicolors = true
  vim.opt.showmode = false
  vim.opt.lazyredraw = true

  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
  vim.opt.foldenable = false
  vim.opt.foldlevel = 99

  vim.opt.pumheight = 10
  vim.opt.cmdheight = 1
  vim.opt.hidden = true
  vim.opt.showtabline = 2
  vim.opt.shortmess:append("c")
  vim.opt.completeopt = { "menuone", "noselect" }
end

local function setup_keybindings()
  local opts = { noremap = true, silent = true }
  
  vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true, desc = "Move to left window" })
  vim.keymap.set("n", "<C-j>", "<C-w>j", { noremap = true, silent = true, desc = "Move to lower window" })
  vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true, silent = true, desc = "Move to upper window" })
  vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true, desc = "Move to right window" })

  vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
  vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)
  vim.keymap.set("n", "n", "nzzzv", opts)
  vim.keymap.set("n", "N", "Nzzzv", opts)

  vim.keymap.set("n", "<D-b>", "<cmd>Oil<CR>", opts)
  vim.keymap.set("n", "<S-CR>", "<cmd>HopWord<CR>", opts)
  vim.keymap.set("i", "<S-CR>", "<Esc><cmd>HopWord<CR>", opts)

  vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", opts)

  vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
  vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
  vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
  vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)

  vim.keymap.set("n", "gcc", "<Plug>(comment_toggle_linewise_current)", {})
  vim.keymap.set("v", "gc", "<Plug>(comment_toggle_linewise_visual)", {})

  return {
    {
      "<leader>", 
      {
        u = {
          name = "󱂬 UI",
          z = { "<cmd>ZenMode<CR>", "Zen Mode" },
          T = { "<cmd>set showtabline=2<CR>", "Show Tab Line" },
          a = { "<cmd>Alpha<CR>", "Alpha" },
          t = { "<cmd>set showtabline=0<CR>", "Hide Tab Line" },
          b = { "<cmd>Oil<CR>", "Oil" },
        },
        w = {
          name = " Window",
          K = { "<C-w>K", "Move Window Up" },
          J = { "<C-w>J", "Move Window Down" },
          H = { "<C-w>H", "Move Window Left" },
          L = { "<C-w>L", "Move Window Right" },
          h = { "<C-w>h", "Focus Left Window" },
          j = { "<C-w>j", "Focus Lower Window" },
          k = { "<C-w>k", "Focus Upper Window" },
          l = { "<C-w>l", "Focus Right Window" },
          ["_"] = { "<C-w>_", "Max Height" },
          ["="] = { "<C-w>=", "Equal Size" },
          o = { "<cmd>only<CR>", "Only Window" },
          w = { "<cmd>close<CR>", "Close Window" },
        },
        c = {
          name = "󰘧 Code",
          c = { "<Plug>(comment_toggle_linewise_current)", "Toggle Comment" },
          a = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code Action" },
          R = { "<cmd>lua vim.lsp.buf.references()<CR>", "References" },
          d = { "<cmd>lua vim.lsp.buf.definition()<CR>", "Definition" },
          h = { "<cmd>lua vim.lsp.buf.hover()<CR>", "Hover" },
          f = { "<cmd>lua vim.lsp.buf.format()<CR>", "Format" },
          i = { "<cmd>lua vim.lsp.buf.implementation()<CR>", "Implementation" },
          r = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename" },
        },
        b = {
          name = "󱅄 Buffer",
          o = { "<cmd>BufferCloseAllButCurrent<CR>", "Close Others" },
          p = { "<cmd>BufferPrevious<CR>", "Previous" },
          n = { "<cmd>BufferNext<CR>", "Next" },
          d = { "<cmd>BufferClose<CR>", "Close" },
        },
        t = {
          name = "󰨚 Toggle",
          p = { "<cmd>TroubleToggle<CR>", "Trouble" },
          o = { "<cmd>SymbolsOutline<CR>", "Symbols Outline" },
          e = { "<cmd>Oil<CR>", "Oil" },
          m = { "<cmd>Telescope commands<CR>", "Commands" },
          b = { "<cmd>lua require('core.utils').toggle_buffer()<CR>", "Toggle Buffer" },
        },
        g = {
          name = "󰊢 Git",
          P = { "<cmd>Git pull<CR>", "Pull" },
          L = { "<cmd>LazyGit<CR>", "LazyGit" },
          D = { "<cmd>Telescope git_status<CR>", "Status (Telescope)" },
          S = { "<cmd>Gitsigns stage_buffer<CR>", "Stage Buffer" },
          b = { "<cmd>Telescope git_branches<CR>", "Branches" },
          U = { "<cmd>Gitsigns reset_buffer_index<CR>", "Reset Buffer Index" },
          c = { "<cmd>Git commit<CR>", "Commit" },
          d = { "<cmd>Gitsigns diffthis<CR>", "Diff This" },
          h = { "<cmd>Gitsigns select_hunk<CR>", "Select Hunk" },
          v = { "<cmd>Telescope git_status<CR>", "Status (View)" },
          f = { "<cmd>Git fetch<CR>", "Fetch" },
          u = { "<cmd>Gitsigns undo_stage_hunk<CR>", "Undo Stage Hunk" },
          r = { "<cmd>Gitsigns reset_hunk<CR>", "Reset Hunk" },
          j = { "<cmd>Gitsigns next_hunk<CR>", "Next Hunk" },
          s = { "<cmd>Gitsigns stage_hunk<CR>", "Stage Hunk" },
          k = { "<cmd>Gitsigns prev_hunk<CR>", "Previous Hunk" },
          p = { "<cmd>Git push<CR>", "Push" },
          l = { "<cmd>Gitsigns reset_hunk<CR>", "Reset Hunk" },
        },
        f = {
          name = "󰀶 Find",
          r = { "<cmd>Telescope oldfiles<CR>", "Recent Files" },
          s = { "<cmd>Telescope lsp_document_symbols<CR>", "Document Symbols" },
          b = { "<cmd>Telescope buffers<CR>", "Buffers" },
          g = { "<cmd>Telescope live_grep<CR>", "Live Grep" },
          f = { "<cmd>Telescope find_files<CR>", "Find Files" },
        },
        s = {
          name = "󰃻 Split",
          s = { "<cmd>split<CR>", "Horizontal Split" },
          v = { "<cmd>vsplit<CR>", "Vertical Split" },
        },
      }
    }
  }
end

local function setup_plugins(keybindings)
  local module_system = {
    ui = {
      "devicons",
      "lualine",
      "neominimap",
      "barbar",
      "themify",
    },
    editor = {
      "which-key",
      "telescope",
      "oil",
      "wilder",
    },
    tools = {
      "comment",
      "hop",
      "treesitter",
      "conform",
      "lazygit",
      "lsp-zero",
      "nvim-lint",
      "copilot",
      "copilot-chat",
      "copilot-cmp",
      "autopairs",
      "alpha",
      "autosession",
    },
  }

  local module_loader = require("core.module_loader")
  local specs = module_loader.get_plugin_specs(module_system)

  table.insert(specs, {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  })

  table.insert(specs, {
    "folke/which-key.nvim", 
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        plugins = {
          marks = true,
          registers = true,
          spelling = {
            enabled = false,
          },
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
          padding = { 1, 1, 1, 1 },
        },
        layout = {
          height = { min = 4, max = 25 },
          width = { min = 20, max = 50 },
          spacing = 5,
          align = "center",
        },
      })

      local wk = require("which-key")
      wk.register(keybindings)
    end,
  })

  require("lazy").setup(specs)
  module_loader.setup_modules(module_system)
end

local function init()
  setup_package_manager()
  setup_leader()
  setup_common_settings()
  setup_neovim_settings()
  
  local keybindings = setup_keybindings()
  
  setup_plugins(keybindings)
end

init()