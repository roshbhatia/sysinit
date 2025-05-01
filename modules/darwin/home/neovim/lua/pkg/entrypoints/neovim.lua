local sysinit_lib = require('lib')

local function setup_keybindings()
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
        silent = true,
        desc = "Toggle file explorer"
    })

    vim.keymap.set("n", "<D-b>", "<cmd>Neotree toggle<CR>", {
        noremap = true,
        silent = true,
        desc = "Toggle file explorer"
    })

    vim.keymap.set("n", "<A-D-jkb>", "<cmd>CopilotChatToggle<CR>", {
        noremap = true,
        silent = true,
        desc = "Toggle Copilot Chat"
    })

    vim.keymap.set("n", "<S-CR>", "<cmd>HopWord<CR>", {
        noremap = true,
        silent = true,
        desc = "Hop to word"
    })

    vim.keymap.set("i", "<S-CR>", "<Esc><cmd>HopWord<CR>", {
        noremap = true,
        silent = true,
        desc = "Hop to word"
    })

    vim.keymap.set("n", "<D-/>", "<Plug>(comment_toggle_linewise_current)", {
        desc = "Toggle comment"
    })

    vim.keymap.set("v", "<D-/>", "<Plug>(comment_toggle_linewise_visual)", {
        desc = "Toggle comment"
    })

    for i = 1, 9 do
        vim.keymap.set("n", "<C-" .. i .. ">", "<cmd>buffer " .. i .. "<CR>", {
            noremap = true,
            silent = true,
            desc = "Switch to buffer " .. i
        })
    end

    vim.keymap.set({"n", "i", "v"}, "<D-s>", "<cmd>w<CR>", {
        noremap = true,
        silent = true,
        desc = "Save file"
    })

    vim.keymap.set({"n", "i", "v"}, "<D-w>", function()
        local buf_count = 0
        for _ in pairs(vim.fn.getbufinfo({
            buflisted = 1
        })) do
            buf_count = buf_count + 1
        end

        if buf_count <= 1 then
            vim.cmd("q")
        else
            vim.cmd("bd")
        end
    end, {
        noremap = true,
        silent = true,
        desc = "Close buffer or quit"
    })

    vim.keymap.set({"n", "i", "v"}, "<D-n>", "<cmd>enew<CR>", {
        noremap = true,
        silent = true,
        desc = "New file"
    })

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

    vim.keymap.set({"n", "i"}, "<D-z>", "<cmd>undo<CR>", {
        noremap = true,
        silent = true,
        desc = "Undo"
    })

    vim.keymap.set({"n", "i"}, "<D-S-z>", "<cmd>redo<CR>", {
        noremap = true,
        silent = true,
        desc = "Redo"
    })

    vim.keymap.set({"n", "v", "i"}, "<D-a>", function()
        if vim.fn.mode() == 'i' then
            return "<Esc>ggVG"
        else
            return "ggVG"
        end
    end, {
        noremap = true,
        expr = true,
        desc = "Select all"
    })

    vim.keymap.set({"n", "i"}, "<D-f>", function()
        if vim.fn.mode() == 'i' then
            return "<Esc>/"
        else
            return "/"
        end
    end, {
        noremap = true,
        expr = true,
        desc = "Find"
    })

    vim.keymap.set("n", "<D-S-f>", "<cmd>Telescope live_grep<CR>", {
        noremap = true,
        silent = true,
        desc = "Find in files"
    })

    vim.keymap.set("n", "<D-p>", "<cmd>Telescope find_files<CR>", {
        noremap = true,
        silent = true,
        desc = "Quick open"
    })

    vim.keymap.set("n", "<D-S-p>", "<cmd>Telescope commands<CR>", {
        noremap = true,
        silent = true,
        desc = "Command palette"
    })
end

local function setup_plugins()
    local ui = {
        dashboard = require("pkg.plugins.ui.dashboard"),
        devicons = require("pkg.plugins.ui.devicons"),
        minimap = require("pkg.plugins.ui.minimap"),
        scrollbar = require("pkg.plugins.ui.scrollbar"),
        statusbar = require("pkg.plugins.ui.statusbar"),
        tab = require("pkg.plugins.ui.tab"),
        smart_splits = require("pkg.plugins.ui.smart-splits")
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
        pallete = require("pkg.plugins.keymaps.pallete"),
        commands = require("pkg.plugins.keymaps.commands")
    }

    local tools = {
        completion_ai = require("pkg.plugins.tools.completion-ai"),
        formatter = require("pkg.plugins.tools.formatter"),
        linters = require("pkg.plugins.tools.linters"),
        lsp = require("pkg.plugins.tools.lsp"),
        parser = require("pkg.plugins.tools.parser"),
        outline = require("pkg.plugins.tools.outline")
    }

    local debugger = {
        dap = require("pkg.plugins.debugger.dap")
    }

    local modules = { -- UI elements
    ui.devicons, ui.statusbar, ui.tab, ui.minimap, ui.scrollbar, ui.smart_splits, ui.dashboard, -- Keymaps
    keymaps.pallete, keymaps.commands, keymaps.hop, -- Editor enhancements
    editor.comment, editor.ibl, -- File management
    file.editor, file.tree, file.telescope, file.session, file.diffview, -- Git integration
    git.client, git.blame, -- Tools
    tools.parser, tools.lsp, tools.formatter, tools.linters, tools.completion_ai, tools.outline, -- Debugging
    debugger.dap}

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

    vim.cmd("Alpha")
end

return M
