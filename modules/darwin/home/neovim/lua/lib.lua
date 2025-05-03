local M = {}

function M.geMecs(modules)
    local specs = {}

    for _, M in ipairs(modules) do
        if M.plugins then
            for _, plugin in ipairs(M.plugins) do
                table.insert(specs, plugin)
            end
        end
    end

    return specs
end

function M.setup_modules(modules)
    for _, M in ipairs(modules) do
        if M.setup then
            M.setup()
        end
    end
end

function M.setup_package_manager(specs)
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git",
                       "--branch=stable", lazypath})
    end
    vim.opt.rtp:prepend(lazypath)

    local core_specs = {{
        "vhyrro/luarocks.nvim",
        priority = 1000,
        dependencies = {"nvim-lua/plenary.nvim"},
        opts = {
            rocks = {},
            rocks_path = vim.fn.stdpath("data") .. "/luarocks",
            lua_path = vim.fn.stdpath("data") .. "/luarocks/share/lua/5.1/?.lua;" .. vim.fn.stdpath("data") ..
                "/luarocks/share/lua/5.1/?/init.lua",
            lua_cpath = vim.fn.stdpath("data") .. "/luarocks/lib/lua/5.1/?.so",
            create_dirs = true,
            install = {
                only_deps = false,
                flags = {"--local", "--force-config"}
            },
            show_progress = true
        }
    }}

    for _, spec in ipairs(specs) do
        table.insert(core_specs, spec)
    end

    for _, spec in ipairs(specs) do
        table.insert(core_specs, spec)
    end

    require("lazy").setup({
        root = vim.fn.stdpath("data") .. "/lazy",
        lockfile = vim.fn.stdpath("data") .. "/lazy/lazy-lock.json",

        rocks = {
            enabled = true,
            root = vim.fn.stdpath("data") .. "/lazy-rocks"
        },

        spec = core_specs,

        performance = {
            rtp = {
                disabled_plugins = {"gzip", "matchit", "matchparen", "netrwPlugin", "tarPlugin", "tohtml", "tutor",
                                    "zipPlugin"}
            }
        },
        change_detection = {
            notify = false
        }
    })
end

function M.setup_settings()
    vim.api.nvim_set_keymap('n', 'q', '<Nop>', {
        noremap = true,
        silent = true
    })

    vim.keymap.set({"n", "v"}, "<Space>", "<Nop>", {
        noremap = true,
        silent = true
    })
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    vim.keymap.set("n", ":", ":", {
        noremap = true,
        desc = "Command mode"
    })

    vim.keymap.set("n", "<C-d>", "<C-d>zz", {
        noremap = true,
        silent = true
    })
    vim.keymap.set("n", "<C-u>", "<C-u>zz", {
        noremap = true,
        silent = true
    })
    vim.keymap.set("n", "n", "nzzzv", {
        noremap = true,
        silent = true
    })
    vim.keymap.set("n", "N", "Nzzzv", {
        noremap = true,
        silent = true
    })
    vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
        noremap = true,
        silent = true
    })

    vim.opt.hlsearch = true
    vim.opt.incsearch = true
    vim.opt.ignorecase = true
    vim.opt.smartcase = true

    vim.opt.expandtab = true
    vim.opt.shiftwidth = 2
    vim.opt.tabstop = 2
    vim.opt.smartindent = true
    vim.opt.wrap = true
    vim.opt.linebreak = true
    vim.opt.breakindent = true

    vim.opt.splitbelow = true
    vim.opt.splitright = true

    vim.opt.updatetime = 100
    vim.opt.timeoutlen = 300
    vim.opt.scrolloff = 8
    vim.opt.sidescrolloff = 8
    vim.opt.mouse = "a"

    vim.opt.number = true
    vim.opt.cursorline = true
    vim.opt.signcolumn = "yes"
    vim.opt.termguicolors = true
    vim.opt.showmode = true
    vim.opt.foldenable = true
    vim.opt.foldlevel = 99
end

return M

