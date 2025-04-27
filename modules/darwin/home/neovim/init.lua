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

  vim.keymap.set("n", "<A-b>", "<cmd>Oil<CR>", opts)
  vim.keymap.set("n", "<S-CR>", "<cmd>HopWord<CR>", opts)
  vim.keymap.set("i", "<S-CR>", "<Esc><cmd>HopWord<CR>", opts)

  vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", opts)

  vim.keymap.set("n", "<D-/>", "<Plug>(comment_toggle_linewise_current)", { desc = "Toggle comment" })
  vim.keymap.set("v", "<D-/>", "<Plug>(comment_toggle_linewise_visual)", { desc = "Toggle comment" })  
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
      "autosession",
      "alpha",
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

      require("which-key").add({
        { "", desc = "<leader>" },
        { "bd", "<cmd>BufferClose<CR>", desc = "Close", group = "󱅄 Buffer" },
        { "bn", "<cmd>BufferNext<CR>", desc = "Next", group = "󱅄 Buffer" },
        { "bo", "<cmd>BufferCloseAllButCurrent<CR>", desc = "Close Others", group = "󱅄 Buffer" },
        { "bp", "<cmd>BufferPrevious<CR>", desc = "Previous", group = "󱅄 Buffer" },
        { "cR", "<cmd>lua vim.lsp.buf.references()<CR>", desc = "References", group = "󰘧 Code" },
        { "ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "Code Action", group = "󰘧 Code" },
        { "cc", "<Plug>(comment_toggle_linewise_current)", desc = "Toggle Comment", group = "󰘧 Code" },
        { "cd", "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "Definition", group = "󰘧 Code" },
        { "cf", "<cmd>lua vim.lsp.buf.format()<CR>", desc = "Format", group = "󰘧 Code" },
        { "ch", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "Hover", group = "󰘧 Code" },
        { "ci", "<cmd>lua vim.lsp.buf.implementation()<CR>", desc = "Implementation", group = "󰘧 Code" },
        { "cr", "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "Rename", group = "󰘧 Code" },
        { "fb", "<cmd>Telescope buffers<CR>", desc = "Buffers", group = "󰀶 Find" },
        { "ff", "<cmd>Telescope find_files<CR>", desc = "Find Files", group = "󰀶 Find" },
        { "fg", "<cmd>Telescope live_grep<CR>", desc = "Live Grep", group = "󰀶 Find" },
        { "fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent Files", group = "󰀶 Find" },
        { "fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document Symbols", group = "󰀶 Find" },
        { "gD", "<cmd>Telescope git_status<CR>", desc = "Status (Telescope)", group = "󰊢 Git" },
        { "gL", "<cmd>LazyGit<CR>", desc = "LazyGit", group = "󰊢 Git" },
        { "gP", "<cmd>Git pull<CR>", desc = "Pull", group = "󰊢 Git" },
        { "gS", "<cmd>Gitsigns stage_buffer<CR>", desc = "Stage Buffer", group = "󰊢 Git" },
        { "gU", "<cmd>Gitsigns reset_buffer_index<CR>", desc = "Reset Buffer Index", group = "󰊢 Git" },
        { "gb", "<cmd>Telescope git_branches<CR>", desc = "Branches", group = "󰊢 Git" },
        { "gc", "<cmd>Git commit<CR>", desc = "Commit", group = "󰊢 Git" },
        { "gd", "<cmd>Gitsigns diffthis<CR>", desc = "Diff This", group = "󰊢 Git" },
        { "gf", "<cmd>Git fetch<CR>", desc = "Fetch", group = "󰊢 Git" },
        { "gh", "<cmd>Gitsigns select_hunk<CR>", desc = "Select Hunk", group = "󰊢 Git" },
        { "gj", "<cmd>Gitsigns next_hunk<CR>", desc = "Next Hunk", group = "󰊢 Git" },
        { "gk", "<cmd>Gitsigns prev_hunk<CR>", desc = "Previous Hunk", group = "󰊢 Git" },
        { "gl", "<cmd>Gitsigns reset_hunk<CR>", desc = "Reset Hunk", group = "󰊢 Git" },
        { "gp", "<cmd>Git push<CR>", desc = "Push", group = "󰊢 Git" },
        { "gr", "<cmd>Gitsigns reset_hunk<CR>", desc = "Reset Hunk", group = "󰊢 Git" },
        { "gs", "<cmd>Gitsigns stage_hunk<CR>", desc = "Stage Hunk", group = "󰊢 Git" },
        { "gu", "<cmd>Gitsigns undo_stage_hunk<CR>", desc = "Undo Stage Hunk", group = "󰊢 Git" },
        { "gv", "<cmd>Telescope git_status<CR>", desc = "Status (View)", group = "󰊢 Git" },
        { "ss", "<cmd>split<CR>", desc = "Horizontal Split", group = "󰃻 Split" },
        { "sv", "<cmd>vsplit<CR>", desc = "Vertical Split", group = "󰃻 Split" },
        { "tb", "<cmd>lua require('core.utils').toggle_buffer()<CR>", desc = "Toggle Buffer", group = "󰨚 Toggle" },
        { "te", "<cmd>Oil<CR>", desc = "Oil", group = "󰨚 Toggle" },
        { "tm", "<cmd>Telescope commands<CR>", desc = "Commands", group = "󰨚 Toggle" },
        { "to", "<cmd>SymbolsOutline<CR>", desc = "Symbols Outline", group = "󰨚 Toggle" },
        { "tp", "<cmd>TroubleToggle<CR>", desc = "Trouble", group = "󰨚 Toggle" },
        { "w=", "<C-w>=", desc = "Equal Size", group = " Window" },
        { "wH", "<C-w>H", desc = "Move Window Left", group = " Window" },
        { "wJ", "<C-w>J", desc = "Move Window Down", group = " Window" },
        { "wK", "<C-w>K", desc = "Move Window Up", group = " Window" },
        { "wL", "<C-w>L", desc = "Move Window Right", group = " Window" },
        { "w_", "<C-w>_", desc = "Max Height", group = " Window" },
        { "wh", "<C-w>h", desc = "Focus Left Window", group = " Window" },
        { "wj", "<C-w>j", desc = "Focus Lower Window", group = " Window" },
        { "wk", "<C-w>k", desc = "Focus Upper Window", group = " Window" },
        { "wl", "<C-w>l", desc = "Focus Right Window", group = " Window" },
        { "wo", "<cmd>only<CR>", desc = "Only Window", group = " Window" },
        { "ww", "<cmd>close<CR>", desc = "Close Window", group = " Window" }, 
      })
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
  setup_keybindings()
  setup_plugins()
end

init()