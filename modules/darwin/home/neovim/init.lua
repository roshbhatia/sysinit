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

    vim.keymap.set("n", "<A-b>", "<cmd>Oil<CR>", {
        noremap = true,
        silent = true
    }) -- Like the alt+b to open up left activity bar in vsc
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
end

local function setup_plugins()
    local ui = {
        devicons = require("modules.ui.devicons"),
        lualine = require("modules.ui.lualine"),
        neominimap = require("modules.ui.neominimap"),
        barbar = require("modules.ui.barbar"),
        themify = require("modules.ui.themify")
    }

    local editor = {
        telescope = require("modules.editor.telescope"),
        oil = require("modules.editor.oil"),
        wilder = require("modules.editor.wilder")
    }

    local tools = {
        comment = require("modules.tools.comment"),
        hop = require("modules.tools.hop"),
        treesitter = require("modules.tools.treesitter"),
        conform = require("modules.tools.conform"),
        git = require("modules.tools.git"),
        ["lsp-zero"] = require("modules.tools.lsp-zero"),
        ["nvim-lint"] = require("modules.tools.nvim-lint"),
        copilot = require("modules.tools.copilot"),
        autopairs = require("modules.tools.autopairs"),
        autosession = require("modules.tools.autosession"),
        alpha = require("modules.tools.alpha"),
        ["which-key"] = require("modules.tools.which-key")
    }

    local modules = {ui.devicons, ui.lualine, ui.neominimap, ui.barbar, ui.themify, editor.telescope, editor.oil,
                     editor.wilder, tools.comment, tools.hop, tools.treesitter, tools.conform, tools.git,
                     tools["lsp-zero"], tools["nvim-lint"], tools.copilot, tools.autopairs, tools.autosession,
                     tools.alpha, tools["which-key"]}

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

    setup_keybindings()
    setup_plugins()
end

init()

vim.cmd("Alpha")
