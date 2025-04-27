local function setup_package_manager()
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git",
                       "--branch=stable", lazypath})
    end
    vim.opt.rtp:prepend(lazypath)

    local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
    local lua_dir = init_dir .. "/lua"
    vim.opt.rtp:prepend(lua_dir)
end

local function setup_leader()
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
    vim.opt.completeopt = {"menuone", "noselect"}
end

local function setup_keybindings()
    local opts = {
        noremap = true,
        silent = true
    }

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

    vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
    vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)
    vim.keymap.set("n", "n", "nzzzv", opts)
    vim.keymap.set("n", "N", "Nzzzv", opts)

    vim.keymap.set("n", "<A-b>", "<cmd>Oil<CR>", opts)
    vim.keymap.set("n", "<S-CR>", "<cmd>HopWord<CR>", opts)
    vim.keymap.set("i", "<S-CR>", "<Esc><cmd>HopWord<CR>", opts)

    vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", opts)

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
        editor = {"which-key", "telescope", "oil", "wilder"},
        tools = {"comment", "hop", "treesitter", "conform", "lazygit", "lsp-zero", "nvim-lint", "copilot",
                 "copilot-chat", "copilot-cmp", "autopairs", "autosession", "alpha"}
    }

    local module_loader = require("core.module_loader")
    local specs = module_loader.get_plugin_specs(module_system)

    table.insert(specs, {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
        end
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
                        enabled = false
                    },
                    presets = {
                        operators = true,
                        motions = true,
                        text_objects = true,
                        windows = true,
                        nav = true,
                        z = true,
                        g = true
                    }
                },
                window = {
                    border = "single",
                    position = "bottom",
                    margin = {1, 0, 1, 0},
                    padding = {1, 1, 1, 1}
                },
                layout = {
                    height = {
                        min = 4,
                        max = 25
                    },
                    width = {
                        min = 20,
                        max = 50
                    },
                    spacing = 5,
                    align = "center"
                }
            })

            require("which-key").add({{
                "<leader>bd",
                "<cmd>BufferClose<CR>",
                group = "󱅄 Buffer",
                desc = "Close"
            }, {
                "<leader>bn",
                "<cmd>BufferNext<CR>",
                group = "󱅄 Buffer",
                desc = "Next"
            }, {
                "<leader>bo",
                "<cmd>BufferCloseAllButCurrent<CR>",
                group = "󱅄 Buffer",
                desc = "Close Others"
            }, {
                "<leader>bp",
                "<cmd>BufferPrevious<CR>",
                group = "󱅄 Buffer",
                desc = "Previous"
            }, {
                "<leader>cR",
                "<cmd>lua vim.lsp.buf.references()<CR>",
                group = "󰘧 Code",
                desc = "References"
            }, {
                "<leader>ca",
                "<cmd>lua vim.lsp.buf.code_action()<CR>",
                group = "󰘧 Code",
                desc = "Code Action"
            }, {
                "<leader>cc",
                "<Plug>(comment_toggle_linewise_current)",
                group = "󰘧 Code",
                desc = "Toggle Comment"
            }, {
                "<leader>cd",
                "<cmd>lua vim.lsp.buf.definition()<CR>",
                group = "󰘧 Code",
                desc = "Definition"
            }, {
                "<leader>cf",
                "<cmd>lua vim.lsp.buf.format()<CR>",
                group = "󰘧 Code",
                desc = "Format"
            }, {
                "<leader>ch",
                "<cmd>lua vim.lsp.buf.hover()<CR>",
                group = "󰘧 Code",
                desc = "Hover"
            }, {
                "<leader>ci",
                "<cmd>lua vim.lsp.buf.implementation()<CR>",
                group = "󰘧 Code",
                desc = "Implementation"
            }, {
                "<leader>cr",
                "<cmd>lua vim.lsp.buf.rename()<CR>",
                group = "󰘧 Code",
                desc = "Rename"
            }, {
                "<leader>fb",
                "<cmd>Telescope buffers<CR>",
                group = "󰀶 Find",
                desc = "Buffers"
            }, {
                "<leader>ff",
                "<cmd>Telescope find_files<CR>",
                group = "󰀶 Find",
                desc = "Find Files"
            }, {
                "<leader>fg",
                "<cmd>Telescope live_grep<CR>",
                group = "󰀶 Find",
                desc = "Live Grep"
            }, {
                "<leader>fr",
                "<cmd>Telescope oldfiles<CR>",
                group = "󰀶 Find",
                desc = "Recent Files"
            }, {
                "<leader>fs",
                "<cmd>Telescope lsp_document_symbols<CR>",
                group = "󰀶 Find",
                desc = "Document Symbols"
            }, {
                "<leader>gD",
                "<cmd>Telescope git_status<CR>",
                group = "󰊢 Git",
                desc = "Status (Telescope)"
            }, {
                "<leader>gL",
                "<cmd>LazyGit<CR>",
                group = "󰊢 Git",
                desc = "LazyGit"
            }, {
                "<leader>gP",
                "<cmd>Git pull<CR>",
                group = "󰊢 Git",
                desc = "Pull"
            }, {
                "<leader>gS",
                "<cmd>Gitsigns stage_buffer<CR>",
                group = "󰊢 Git",
                desc = "Stage Buffer"
            }, {
                "<leader>gU",
                "<cmd>Gitsigns reset_buffer_index<CR>",
                group = "󰊢 Git",
                desc = "Reset Buffer Index"
            }, {
                "<leader>gb",
                "<cmd>Telescope git_branches<CR>",
                group = "󰊢 Git",
                desc = "Branches"
            }, {
                "<leader>gc",
                "<cmd>Git commit<CR>",
                group = "󰊢 Git",
                desc = "Commit"
            }, {
                "<leader>gd",
                "<cmd>Gitsigns diffthis<CR>",
                group = "󰊢 Git",
                desc = "Diff This"
            }, {
                "<leader>gf",
                "<cmd>Git fetch<CR>",
                group = "󰊢 Git",
                desc = "Fetch"
            }, {
                "<leader>gh",
                "<cmd>Gitsigns select_hunk<CR>",
                group = "󰊢 Git",
                desc = "Select Hunk"
            }, {
                "<leader>gj",
                "<cmd>Gitsigns next_hunk<CR>",
                group = "󰊢 Git",
                desc = "Next Hunk"
            }, {
                "<leader>gk",
                "<cmd>Gitsigns prev_hunk<CR>",
                group = "󰊢 Git",
                desc = "Previous Hunk"
            }, {
                "<leader>gl",
                "<cmd>Gitsigns reset_hunk<CR>",
                group = "󰊢 Git",
                desc = "Reset Hunk"
            }, {
                "<leader>gp",
                "<cmd>Git push<CR>",
                group = "󰊢 Git",
                desc = "Push"
            }, {
                "<leader>gr",
                "<cmd>Gitsigns reset_hunk<CR>",
                group = "󰊢 Git",
                desc = "Reset Hunk"
            }, {
                "<leader>gs",
                "<cmd>Gitsigns stage_hunk<CR>",
                group = "󰊢 Git",
                desc = "Stage Hunk"
            }, {
                "<leader>gu",
                "<cmd>Gitsigns undo_stage_hunk<CR>",
                group = "󰊢 Git",
                desc = "Undo Stage Hunk"
            }, {
                "<leader>gv",
                "<cmd>Telescope git_status<CR>",
                group = "󰊢 Git",
                desc = "Status (View)"
            }, {
                "<leader>ss",
                "<cmd>split<CR>",
                group = "󰃻 Split",
                desc = "Horizontal Split"
            }, {
                "<leader>sv",
                "<cmd>vsplit<CR>",
                group = "󰃻 Split",
                desc = "Vertical Split"
            }, {
                "<leader>tm",
                "<cmd>Telescope commands<CR>",
                group = "󰨚 Toggle",
                desc = "Commands"
            }, {
                "<leader>to",
                "<cmd>SymbolsOutline<CR>",
                group = "󰨚 Toggle",
                desc = "Symbols Outline"
            }, {
                "<leader>tp",
                "<cmd>TroubleToggle<CR>",
                group = "󰨚 Toggle",
                desc = "Trouble"
            }, {
                "<leader>w=",
                "<C-w>=",
                group = " Window",
                desc = "Equal Size"
            }, {
                "<leader>wH",
                "<C-w>H",
                group = " Window",
                desc = "Move Window Left"
            }, {
                "<leader>wJ",
                "<C-w>J",
                group = " Window",
                desc = "Move Window Down"
            }, {
                "<leader>wK",
                "<C-w>K",
                group = " Window",
                desc = "Move Window Up"
            }, {
                "<leader>wL",
                "<C-w>L",
                group = " Window",
                desc = "Move Window Right"
            }, {
                "<leader>w_",
                "<C-w>_",
                group = " Window",
                desc = "Max Height"
            }, {
                "<leader>wh",
                "<C-w>h",
                group = " Window",
                desc = "Focus Left Window"
            }, {
                "<leader>wj",
                "<C-w>j",
                group = " Window",
                desc = "Focus Lower Window"
            }, {
                "<leader>wk",
                "<C-w>k",
                group = " Window",
                desc = "Focus Upper Window"
            }, {
                "<leader>wl",
                "<C-w>l",
                group = " Window",
                desc = "Focus Right Window"
            }, {
                "<leader>wo",
                "<cmd>only<CR>",
                group = " Window",
                desc = "Only Window"
            }, {
                "<leader>ww",
                "<cmd>close<CR>",
                group = " Window",
                desc = "Close Window"
            }})
        end
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
