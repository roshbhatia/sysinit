vim.g.vscode = false

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
    f = {
      name = "󰀶 Find",
      f = { "<cmd>Telescope find_files<CR>", "Find Files" },
      g = { "<cmd>Telescope live_grep<CR>", "Find in Files" },
      b = { "<cmd>Telescope buffers<CR>", "Find Buffers" },
      s = { "<cmd>Telescope lsp_document_symbols<CR>", "Find Symbols" },
      r = { "<cmd>Telescope oldfiles<CR>", "Recent Files" },
    },
    w = {
      name = "󱂬 Window",
      h = { "<C-w>h", "Focus Left" },
      j = { "<C-w>j", "Focus Down" },
      k = { "<C-w>k", "Focus Up" },
      l = { "<C-w>l", "Focus Right" },
      ["="] = { "<C-w>=", "Equal Width" },
      ["_"] = { "<C-w>_", "Max Height" },
      w = { "<cmd>close<CR>", "Close Window" },
      o = { "<cmd>only<CR>", "Close Others" },
      H = { "<C-w>H", "Move Left" },
      J = { "<C-w>J", "Move Down" },
      K = { "<C-w>K", "Move Up" },
      L = { "<C-w>L", "Move Right" },
    },
    u = {
      name = " UI",
      a = { "<cmd>Alpha<CR>", "Dashboard" },
      t = { "<cmd>set showtabline=0<CR>", "Hide Tab Bar" },
      T = { "<cmd>set showtabline=2<CR>", "Show Tab Bar" },
      b = { "<cmd>Oil<CR>", "File Browser" },
      z = { "<cmd>ZenMode<CR>", "Zen Mode" },
    },
    b = {
      name = " Buffer",
      n = { "<cmd>BufferNext<CR>", "Next Buffer" },
      p = { "<cmd>BufferPrevious<CR>", "Previous Buffer" },
      d = { "<cmd>BufferClose<CR>", "Close Buffer" },
      o = { "<cmd>BufferCloseAllButCurrent<CR>", "Close Others" },
    },
    g = {
      name = " Git",
      s = { "<cmd>Gitsigns stage_hunk<CR>", "Stage Hunk" },
      S = { "<cmd>Gitsigns stage_buffer<CR>", "Stage All" },
      u = { "<cmd>Gitsigns undo_stage_hunk<CR>", "Unstage Hunk" },
      U = { "<cmd>Gitsigns reset_buffer_index<CR>", "Unstage All" },
      c = { "<cmd>Git commit<CR>", "Commit" },
      p = { "<cmd>Git push<CR>", "Push" },
      P = { "<cmd>Git pull<CR>", "Pull" },
      d = { "<cmd>Gitsigns diffthis<CR>", "Open Change" },
      D = { "<cmd>Telescope git_status<CR>", "Open All Changes" },
      b = { "<cmd>Telescope git_branches<CR>", "Checkout Branch" },
      f = { "<cmd>Git fetch<CR>", "Fetch" },
      r = { "<cmd>Gitsigns reset_hunk<CR>", "Revert Change" },
      v = { "<cmd>Telescope git_status<CR>", "SCM View" },
      e = { "<cmd>Oil<CR>", "Open File Explorer" },
      h = { "<cmd>Gitsigns select_hunk<CR>", "Stage Selected Ranges" },
      j = { "<cmd>Gitsigns next_hunk<CR>", "Next Change" },
      k = { "<cmd>Gitsigns prev_hunk<CR>", "Previous Change" },
      l = { "<cmd>Gitsigns reset_hunk<CR>", "Unstage Selected Ranges" },
      L = { "<cmd>LazyGit<CR>", "LazyGit" },
    },
    c = {
      name = "󰘧 Code",
      a = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Quick Fix" },
      r = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename Symbol" },
      f = { "<cmd>lua vim.lsp.buf.format()<CR>", "Format Document" },
      d = { "<cmd>lua vim.lsp.buf.definition()<CR>", "Go to Definition" },
      i = { "<cmd>lua vim.lsp.buf.implementation()<CR>", "Go to Implementation" },
      h = { "<cmd>lua vim.lsp.buf.hover()<CR>", "Show Hover" },
      c = { "<Plug>(comment_toggle_linewise_current)", "Toggle Comment" },
      s = { "<cmd>Telescope lsp_document_symbols<CR>", "Go to Symbol" },
      R = { "<cmd>lua vim.lsp.buf.references()<CR>", "Find References" },
    },
    t = {
      name = "󰨚 Toggle",
      e = { "<cmd>Oil<CR>", "Explorer" },
      t = { "<cmd>terminal<CR>", "Terminal" },
      p = { "<cmd>TroubleToggle<CR>", "Problems" },
      o = { "<cmd>SymbolsOutline<CR>", "Outline" },
      b = { "<cmd>lua require('core.utils').toggle_buffer()<CR>", "Return to Editor" },
      m = { "<cmd>Telescope commands<CR>", "Command Palette" },
    },
    s = {
      name = "󰓩 Split",
      s = { "<cmd>split<CR>", "Split Horizontal" },
      v = { "<cmd>vsplit<CR>", "Split Vertical" },
    },
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
      "neoscroll",
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
      wk.register(keybindings, { prefix = "<leader>" })
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