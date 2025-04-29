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
        notify = require("modules.ui.notify"),
        devicons = require("modules.ui.devicons"),
        lualine = require("modules.ui.lualine"),
        neominimap = require("modules.ui.neominimap"),
        barbar = require("modules.ui.barbar"),
        themify = require("modules.ui.themify"),
        tree = require("modules.ui.tree"),
        scrollbar = require("modules.ui.scrollbar")
    }

    local editor = {
        telescope = require("modules.editor.telescope"),
        oil = require("modules.editor.oil"),
        wilder = require("modules.editor.wilder")
        ibl = require("modules.editor.ibl")
 
    }

    local tools = {
        comment = require("modules.tools.comment"),
        hop = require("modules.tools.hop"),
        treesitter = require("modules.tools.treesitter"),
        conform = require("modules.tools.conform"),
        git = require("modules.tools.git"),
        blame = require("modules.tools.blame"),
        ["nvim-tree"] = require("modules.tools.nvim-tree"),
        ["nvim-autopairs"] = require("modules.tools.nvim-autopairs"),
        ["nvim-ts-autotag"] = require("modules.tools.nvim-ts-autotag"),
        ["nvim-surround"] = require("modules.tools.nvim-surround"),
        ["nvim-comment"] = require("modules.tools.nvim-comment"),
        ["nvim-colorizer"] = require("modules.tools.nvim-colorizer"),
        ["nvim-notify"] = require("modules.tools.nvim-notify"),
        ["nvim-web-devicons"] = require("modules.tools.nvim-web-devicons"),
        ["lspkind-nvim"] = require("modules.tools.lspkind-nvim"),
        ["lsp-zero"] = require("modules.tools.lsp-zero"),
        ["mason-lspconfig"] = require("modules.tools.mason-lspconfig"),
        ["mason-null-ls"] = require("modules.tools.mason-null-ls"),
        ["nvim-lint"] = require("modules.tools.nvim-lint"),
        cmp = require("modules.tools.cmp"),
        autopairs = require("modules.tools.autopairs"),
        autosession = require("modules.tools.autosession"),
        alpha = require("modules.tools.alpha"),
        ["which-key"] = require("modules.tools.which-key")
    }
    local modules = {ui.devicons, ui.themify, tools.treesitter, editor.oil, ui.tree, ui.scrollbar, editor.telescope, tools.autopairs,
                     tools.comment, tools.conform, tools["nvim-lint"], tools.hop, ui.lualine, ui.barbar, ui.neominimap,
                    tools.git, tools.blame, tools.cmp, editor.wilder, tools.autosession, tools.alpha, tools["which-key"], editor.ibl }

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
