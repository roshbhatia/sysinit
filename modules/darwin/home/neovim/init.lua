local function setup_keybindings()
    -- ctrl + hjkl for moving between panes
    vim.keymap.set("n", "<C-h>", "<C-w>h", {
        noremap = true,
        silent = true,
        desc = "Move to left window"
    })
    vim.keymap.set("n", "<C-j>", "<C-w>j", {
        noremap = true,
        silent = true,
        desc = "Move to lower window"
    })
    vim.keymap.set("n", "<C-k>", "<C-w>k", {
        noremap = true,
        silent = true,
        desc = "Move to upper window"
    })
    vim.keymap.set("n", "<C-l>", "<C-w>l", {
        noremap = true,
        silent = true,
        desc = "Move to right window"
    })

    vim.keymap.set("n", "<A-b>", "<cmd>Neotree toggle<CR>", {
        noremap = true,
        silent = true
    }) -- Like the alt+b to open up left activity bar in vsc
    vim.keymap.set("n", "<A-D-jkb>", "<cmd>CopilotChatToggle<CR>", {
        noremap = true,
        silent = true
    }) -- Like the alt+cmd+b to open up chat in vsc
    vim.keymap.set("n", "<S-CR>", "<cmd>HopWord<CR>", {
        noremap = true,
        silent = true
    }) -- Like the jumpy2 shift+enter in vsc
    vim.keymap.set("i", "<S-CR>", "<Esc><cmd>HopWord<CR>", {
        noremap = true,
        silent = true
    })

    -- Like the cmd + / to toggle block comments in vsc
    vim.keymap.set("n", "<D-/>", "<Plug>(comment_toggle_linewise_current)", {
        desc = "Toggle comment"
    })
    vim.keymap.set("v", "<D-/>", "<Plug>(comment_toggle_linewise_visual)", {
        desc = "Toggle comment"
    })

    -- Buffer switching with Ctrl + number keys
    for i = 1, 9 do
        vim.keymap.set("n", "<C-" .. i .. ">", "<cmd>buffer " .. i .. "<CR>", {
            noremap = true,
            silent = true,
            desc = "Switch to buffer " .. i
        })
    end

    -- VSCode-like save with Cmd+s
    vim.keymap.set({"n", "i", "v"}, "<D-s>", "<cmd>w<CR>", {
        noremap = true,
        silent = true,
        desc = "Save file"
    })

    -- VSCode-like copy/cut/paste
    vim.keymap.set("v", "<D-c>", '"+y', {
        noremap = true,
        silent = true,
        desc = "Copy to clipboard"
    })
    vim.keymap.set({"n", "i"}, "<D-c>", '<cmd>let @+=@"<CR>', {
        noremap = true,
        silent = true,
        desc = "Copy to clipboard"
    })
    vim.keymap.set("v", "<D-x>", '"+d', {
        noremap = true,
        silent = true,
        desc = "Cut to clipboard"
    })
    vim.keymap.set({"n", "i", "v"}, "<D-p>", '"+p', {
        noremap = true,
        silent = true,
        desc = "Paste from clipboard"
    })
end

local function setup_plugins()
    local ui = {
        alpha = require("modules.ui.alpha"),
        devicons = require("modules.ui.devicons"),
        lualine = require("modules.ui.lualine"),
        neominimap = require("modules.ui.neominimap"),
        notify = require("modules.ui.notify"),
        scrollbar = require("modules.ui.scrollbar"),
        tab = require("modules.ui.tab"),
        theme = require("modules.ui.theme"),
        tree = require("modules.ui.tree"),
        wilder = require("modules.ui.wilder")
    }

    local editor = {
        ibl = require("modules.editor.ibl"),
        oil = require("modules.editor.oil")
    }

    local tools = {
        autopairs = require("modules.tools.autopairs"),
        autosession = require("modules.tools.autosession"),
        blame = require("modules.tools.blame"),
        cmp = require("modules.tools.cmp"),
        comment = require("modules.tools.comment"),
        conform = require("modules.tools.conform"),
        diffview = require("modules.tools.diffview"),
        git = require("modules.tools.git"),
        hop = require("modules.tools.hop"),
        ["nvim-lint"] = require("modules.tools.nvim-lint"),
        telescope = require("modules.tools.telescope"),
        treesitter = require("modules.tools.treesitter"),
        ["which-key"] = require("modules.tools.which-key")
    }

    local modules = { -- Core UI foundations
    ui.notify, -- Notification system
    ui.theme, -- Theme
    ui.devicons, -- Icons should load early for other UI elements
    -- Essential editor components  
    tools.treesitter, -- Syntax parsing foundation for many plugins
    editor.ibl, -- Indentation guides (relies on treesitter)
    -- File navigation/management
    editor.oil, -- File navigator
    ui.tree, -- File tree (alternative to oil)
    ui.scrollbar, -- Scrollbar enhancement
    -- Git integration
    tools.git, -- Core git functionality
    tools.blame, -- Git blame integration 
    tools.diffview, -- Git diff viewer
    -- Search and navigation
    tools.telescope, -- Fuzzy finder (used by many plugins)
    tools.hop, -- Quick navigation
    -- Code editing enhancements
    tools.autopairs, -- Auto-pairing brackets, etc.
    tools.comment, -- Code commenting functionality
    tools.conform, -- Code formatting
    tools["nvim-lint"], -- Linting
    -- Completion and helpers
    tools.cmp, -- Completion engine
    tools["which-key"], -- Keybinding helper
    ui.wilder, -- Command line completion
    -- UI enhancements
    ui.lualine, -- Status line
    ui.tab, -- Tab bar
    ui.neominimap, -- Minimap
    -- Session and startup
    tools.autosession, -- Session management
    ui.alpha -- Dashboard/greeter
    }

    local module_loader = require("common.module_loader")
    local specs = module_loader.get_plugin_specs(modules)
    require('common.settings').setup_package_manager(specs)
    module_loader.setup_modules(modules)
end

local function init()
    local config_path = vim.fn.stdpath('config')
    package.path = package.path .. ";" .. config_path .. "/?.lua" .. ";" .. config_path .. "/lua/?.lua"
    require('common.settings').setup_settings()

    -- Custom settings
    vim.opt.foldmethod = "expr"
    vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

    vim.opt.pumheight = 10
    vim.opt.cmdheight = 1
    vim.opt.hidden = true
    vim.opt.showtabline = 2
    vim.opt.shortmess:append("c")
    vim.opt.completeopt = {"menuone", "noselect"}
    vim.opt.clipboard = "unnamedplus"

    setup_plugins()
    setup_keybindings()
end

init()

vim.cmd("Alpha")
