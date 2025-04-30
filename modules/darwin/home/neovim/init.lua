local sysinit_lib = require('lib')

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
        alpha = require("plugins.configs.ui.alpha"),
        devicons = require("plugins.configs.ui.devicons"),
        lualine = require("plugins.configs.ui.lualine"),
        neominimap = require("plugins.configs.ui.neominimap"),
        notify = require("plugins.configs.ui.notify"),
        scrollbar = require("plugins.configs.ui.scrollbar"),
        tab = require("plugins.configs.ui.tab"),
        theme = require("plugins.configs.ui.theme"),
        tree = require("plugins.configs.ui.tree"),
        wilder = require("plugins.configs.ui.wilder")
    }

    local editor = {
        ibl = require("plugins.configs.editor.ibl"),
        oil = require("plugins.configs.editor.oil")
    }

    local tools = {
        autosession = require("plugins.configs.tools.autosession"),
        blame = require("plugins.configs.tools.blame"),
        intelligence = require("plugins.configs.tools.intelligence"),
        comment = require("plugins.configs.tools.comment"),
        conform = require("plugins.configs.tools.conform"),
        diffview = require("plugins.configs.tools.diffview"),
        git = require("plugins.configs.tools.git"),
        hop = require("plugins.configs.tools.hop"),
        ["nvim-lint"] = require("plugins.configs.tools.nvim-lint"),
        telescope = require("plugins.configs.tools.telescope"),
        treesitter = require("plugins.configs.tools.treesitter"),
        ["which-key"] = require("plugins.configs.tools.which-key")
    }

    local modules = {ui.notify, ui.theme, ui.devicons, tools.treesitter, editor.ibl, editor.oil, ui.tree, ui.scrollbar,
                     tools.git, tools.blame, tools.diffview, tools.telescope, tools.hop, tools.comment, tools.conform,
                     tools["nvim-lint"], tools.intelligence, tools["which-key"], ui.wilder, ui.lualine, ui.tab,
                     ui.neominimap, tools.autosession, ui.alpha}

    local specs = sysinit_lib.get_plugin_specs(modules)
    sysinit_lib.setup_package_manager(specs)
    sysinit_lib.setup_modules(modules)
end

local function init()
    local config_path = vim.fn.stdpath('config')
    package.path = package.path .. ";" .. config_path .. "/?.lua" .. ";" .. config_path .. "/lua/?.lua"
    sysinit_lib.setup_settings()

    -- Custom settings
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

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
