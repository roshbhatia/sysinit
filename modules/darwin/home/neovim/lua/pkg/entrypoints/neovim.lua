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
        dashboard = require("pkg.plugins.ui.dashboard"),
        devicons = require("pkg.plugins.ui.devicons"),
        minimap = require("pkg.plugins.ui.minimap"),
        notifications = require("pkg.plugins.ui.notifications"),
        pallete = require("pkg.plugins.ui.pallete"),
        scrollbar = require("pkg.plugins.ui.scrollbar"),
        statusbar = require("pkg.plugins.ui.statusbar"),
        tab = require("pkg.plugins.ui.tab"),
        theme = require("pkg.plugins.ui.theme")
    }

    local editor = {
        comment = require("pkg.plugins.editor.comment"),
        ibl = require("pkg.plugins.editor.ibl")
    }

    local file = {
        diffview = require("pkg.plugins.file.diffview"),
        editor = require("pkg.plugins.file.editor"),
        session = require("pkg.plugins.file.session"),
        telescope = require("pkg.plugins.file.telescope"),
        tree = require("pkg.plugins.file.tree")
    }

    local git = {
        blame = require("pkg.plugins.git.blame"),
        client = require("pkg.plugins.git.client")
    }

    local keymaps = {
        hop = require("pkg.plugins.keymaps.hop"),
        leader_pallete = require("pkg.plugins.keymaps.leader-pallete")
    }

    local tools = {
        completion_ai = require("pkg.plugins.tools.completion-ai"),
        formatter = require("pkg.plugins.tools.formatter"),
        linters = require("pkg.plugins.tools.linters"),
        lsp = require("pkg.plugins.tools.lsp"),
        parser = require("pkg.plugins.tools.parser")
    }

    local modules = {ui.dashboard, ui.devicons, ui.minimap, ui.notifications, ui.pallete, ui.scrollbar, ui.statusbar,
                     ui.tab, ui.theme, editor.comment, editor.ibl, file.diffview, file.editor, file.session,
                     file.telescope, file.tree, git.blame, git.client, keymaps.hop, keymaps.leader_pallete,
                     tools.completion_ai, tools.formatter, tools.linters, tools.lsp, tools.parser}

    local specs = sysinit_lib.get_plugin_specs(modules)
    sysinit_lib.setup_package_manager(specs)
    sysinit_lib.setup_modules(modules)
end

local M = {}

function M.init()
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

return M
