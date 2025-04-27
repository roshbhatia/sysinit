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

local function setup_plugins(keybindings)
    local module_system = {
        ui = {"devicons", "lualine", "neominimap", "barbar", "themify"},
        editor = {"telescope", "oil", "wilder"},
        tools = {"comment", "hop", "treesitter", "conform", "git", "lsp-zero", "nvim-lint", "copilot", "copilot-chat",
                 "copilot-cmp", "autopairs", "autosession", "alpha", "which-key"}
    }

    local module_loader = require("core.module_loader")
    local specs = module_loader.get_plugin_specs(module_system)

    require("lazy").setup(specs)
    module_loader.setup_modules(module_system)
end

local function init()
    local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
    vim.opt.rtp:prepend(init_dir)

    local settings = require('common.settings')
    settings.setup_package_manager()
    settings.setup_settings()

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
