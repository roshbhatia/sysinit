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

  return   {
    { "", desc = "<leader>" },
    { "b", group = "󱅄 Buffer" },
    { "bd", "<cmd>BufferClose<CR>", desc = "Close" },
    { "bn", "<cmd>BufferNext<CR>", desc = "Next" },
    { "bo", "<cmd>BufferCloseAllButCurrent<CR>", desc = "Close Others" },
    { "bp", "<cmd>BufferPrevious<CR>", desc = "Previous" },
    { "c", group = "󰘧 Code" },
    { "cR", "<cmd>lua vim.lsp.buf.references()<CR>", desc = "References" },
    { "ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "Code Action" },
    { "cc", "<Plug>(comment_toggle_linewise_current)", desc = "Toggle Comment" },
    { "cd", "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "Definition" },
    { "cf", "<cmd>lua vim.lsp.buf.format()<CR>", desc = "Format" },
    { "ch", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "Hover" },
    { "ci", "<cmd>lua vim.lsp.buf.implementation()<CR>", desc = "Implementation" },
    { "cr", "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "Rename" },
    { "f", group = "󰀶 Find" },
    { "fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "ff", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
    { "fg", "<cmd>Telescope live_grep<CR>", desc = "Live Grep" },
    { "fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent Files" },
    { "fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document Symbols" },
    { "g", group = "󰊢 Git" },
    { "gD", "<cmd>Telescope git_status<CR>", desc = "Status (Telescope)" },
    { "gL", "<cmd>LazyGit<CR>", desc = "LazyGit" },
    { "gP", "<cmd>Git pull<CR>", desc = "Pull" },
    { "gS", "<cmd>Gitsigns stage_buffer<CR>", desc = "Stage Buffer" },
    { "gU", "<cmd>Gitsigns reset_buffer_index<CR>", desc = "Reset Buffer Index" },
    { "gb", "<cmd>Telescope git_branches<CR>", desc = "Branches" },
    { "gc", "<cmd>Git commit<CR>", desc = "Commit" },
    { "gd", "<cmd>Gitsigns diffthis<CR>", desc = "Diff This" },
    { "gf", "<cmd>Git fetch<CR>", desc = "Fetch" },
    { "gh", "<cmd>Gitsigns select_hunk<CR>", desc = "Select Hunk" },
    { "gj", "<cmd>Gitsigns next_hunk<CR>", desc = "Next Hunk" },
    { "gk", "<cmd>Gitsigns prev_hunk<CR>", desc = "Previous Hunk" },
    { "gl", "<cmd>Gitsigns reset_hunk<CR>", desc = "Reset Hunk" },
    { "gp", "<cmd>Git push<CR>", desc = "Push" },
    { "gr", "<cmd>Gitsigns reset_hunk<CR>", desc = "Reset Hunk" },
    { "gs", "<cmd>Gitsigns stage_hunk<CR>", desc = "Stage Hunk" },
    { "gu", "<cmd>Gitsigns undo_stage_hunk<CR>", desc = "Undo Stage Hunk" },
    { "gv", "<cmd>Telescope git_status<CR>", desc = "Status (View)" },
    { "s", group = "󰃻 Split" },
    { "ss", "<cmd>split<CR>", desc = "Horizontal Split" },
    { "sv", "<cmd>vsplit<CR>", desc = "Vertical Split" },
    { "t", group = "󰨚 Toggle" },
    { "tb", "<cmd>lua require('core.utils').toggle_buffer()<CR>", desc = "Toggle Buffer" },
    { "te", "<cmd>Oil<CR>", desc = "Oil" },
    { "tm", "<cmd>Telescope commands<CR>", desc = "Commands" },
    { "to", "<cmd>SymbolsOutline<CR>", desc = "Symbols Outline" },
    { "tp", "<cmd>TroubleToggle<CR>", desc = "Trouble" },
    { "u", group = "󱂬 UI" },
    { "uT", "<cmd>set showtabline=2<CR>", desc = "Show Tab Line" },
    { "ua", "<cmd>Alpha<CR>", desc = "Alpha" },
    { "ub", "<cmd>Oil<CR>", desc = "Oil" },
    { "ut", "<cmd>set showtabline=0<CR>", desc = "Hide Tab Line" },
    { "uz", "<cmd>ZenMode<CR>", desc = "Zen Mode" },
    { "w", group = " Window" },
    { "w=", "<C-w>=", desc = "Equal Size" },
    { "wH", "<C-w>H", desc = "Move Window Left" },
    { "wJ", "<C-w>J", desc = "Move Window Down" },
    { "wK", "<C-w>K", desc = "Move Window Up" },
    { "wL", "<C-w>L", desc = "Move Window Right" },
    { "w_", "<C-w>_", desc = "Max Height" },
    { "wh", "<C-w>h", desc = "Focus Left Window" },
    { "wj", "<C-w>j", desc = "Focus Lower Window" },
    { "wk", "<C-w>k", desc = "Focus Upper Window" },
    { "wl", "<C-w>l", desc = "Focus Right Window" },
    { "wo", "<cmd>only<CR>", desc = "Only Window" },
    { "ww", "<cmd>close<CR>", desc = "Close Window" },
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