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
        editor = {"telescope", "oil", "wilder"},
        tools = {"comment", "hop", "treesitter", "conform", "git", "lsp-zero", "nvim-lint", "copilot", "copilot-chat",
                 "copilot-cmp", "autopairs", "autosession", "alpha"}
    }

    local module_loader = require("core.module_loader")
    local specs = module_loader.get_plugin_specs(module_system)

    table.insert(specs, {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            require("which-key").setup({
                plugins = {
                    marks = true,
                    registers = true,
                    spelling = {
                        enabled = true,
                        suggestions = 20
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
                win = {
                    border = "rounded",
                    padding = {2, 2, 2, 2}
                },
                layout = {
                    spacing = 3
                },
                icons = {
                    breadcrumb = "»",
                    separator = "➜",
                    group = "+"
                },
                show_help = true,
                show_keys = true,
                triggers = {{
                    "<auto>",
                    mode = "nxsotc"
                }}
            })

            require("which-key").add({{
                "<leader>b",
                group = "󱅄 Buffer"
            }, {
                "<leader>bd",
                "<cmd>BufferClose<CR>",
                desc = "Close"
            }, {
                "<leader>bn",
                "<cmd>BufferNext<CR>",
                desc = "Next"
            }, {
                "<leader>bo",
                "<cmd>BufferCloseAllButCurrent<CR>",
                desc = "Close Others"
            }, {
                "<leader>bp",
                "<cmd>BufferPrevious<CR>",
                desc = "Previous"
            }, {
                "<leader>bi",
                function()
                    vim.ui.input({
                        prompt = "Enter file path: "
                    }, function(input)
                        if input then
                            -- Create parent directories if they don't exist
                            local dir = vim.fn.fnamemodify(input, ":h")
                            if dir ~= "." and vim.fn.isdirectory(dir) == 0 then
                                vim.fn.mkdir(dir, "p")
                            end
                            vim.cmd("edit " .. input)
                        end
                    end)
                end,
                desc = "New File"
            }, {
                "<leader>c",
                group = "󰘧 Code"
            }, {
                "<leader>cR",
                "<cmd>lua vim.lsp.buf.references()<CR>",
                desc = "References"
            }, {
                "<leader>ca",
                "<cmd>lua vim.lsp.buf.code_action()<CR>",
                desc = "Code Action"
            }, {
                "<leader>cc",
                "<Plug>(comment_toggle_linewise_current)",
                desc = "Toggle Comment"
            }, {
                "<leader>cd",
                "<cmd>lua vim.lsp.buf.definition()<CR>",
                desc = "Definition"
            }, {
                "<leader>cf",
                "<cmd>lua vim.lsp.buf.format()<CR>",
                desc = "Format"
            }, {
                "<leader>ch",
                "<cmd>lua vim.lsp.buf.hover()<CR>",
                desc = "Hover"
            }, {
                "<leader>ci",
                "<cmd>lua vim.lsp.buf.implementation()<CR>",
                desc = "Implementation"
            }, {
                "<leader>cr",
                "<cmd>lua vim.lsp.buf.rename()<CR>",
                desc = "Rename"
            }, {
                "<leader>f",
                group = "󰀶 Find"
            }, {
                "<leader>fb",
                "<cmd>Telescope buffers<CR>",
                desc = "Buffers"
            }, {
                "<leader>ff",
                "<cmd>Telescope find_files<CR>",
                desc = "Find Files"
            }, {
                "<leader>fg",
                "<cmd>Telescope live_grep<CR>",
                desc = "Live Grep"
            }, {
                "<leader>fr",
                "<cmd>Telescope oldfiles<CR>",
                desc = "Recent Files"
            }, {
                "<leader>fs",
                "<cmd>Telescope lsp_document_symbols<CR>",
                desc = "Document Symbols"
            }, {
                "<leader>g",
                group = "󰊢 Git"
            }, {
                "<leader>gD",
                "<cmd>Telescope git_status<CR>",
                desc = "Status"
            }, {
                "<leader>gL",
                "<cmd>LazyGit<CR>",
                desc = "LazyGit"
            }, {
                "<leader>gP",
                "<cmd>Git pull<CR>",
                desc = "Pull"
            }, {
                "<leader>gS",
                "<cmd>Gitsigns stage_buffer<CR>",
                desc = "Stage Buffer"
            }, {
                "<leader>gU",
                "<cmd>Gitsigns reset_buffer_index<CR>",
                desc = "Reset Buffer Index"
            }, {
                "<leader>gb",
                "<cmd>Telescope git_branches<CR>",
                desc = "Branches"
            }, {
                "<leader>gc",
                "<cmd>Git commit<CR>",
                desc = "Commit"
            }, {
                "<leader>gd",
                "<cmd>Gitsigns diffthis<CR>",
                desc = "Diff This"
            }, {
                "<leader>gf",
                "<cmd>Git fetch<CR>",
                desc = "Fetch"
            }, {
                "<leader>gh",
                "<cmd>Gitsigns select_hunk<CR>",
                desc = "Select Hunk"
            }, {
                "<leader>gj",
                "<cmd>Gitsigns next_hunk<CR>",
                desc = "Next Hunk"
            }, {
                "<leader>gk",
                "<cmd>Gitsigns prev_hunk<CR>",
                desc = "Previous Hunk"
            }, {
                "<leader>gl",
                "<cmd>Gitsigns reset_hunk<CR>",
                desc = "Reset Hunk"
            }, {
                "<leader>gp",
                "<cmd>Git push<CR>",
                desc = "Push"
            }, {
                "<leader>gr",
                "<cmd>Gitsigns reset_hunk<CR>",
                desc = "Reset Hunk"
            }, {
                "<leader>gs",
                "<cmd>Gitsigns stage_hunk<CR>",
                desc = "Stage Hunk"
            }, {
                "<leader>gu",
                "<cmd>Gitsigns undo_stage_hunk<CR>",
                desc = "Undo Stage Hunk"
            }, {
                "<leader>gv",
                "<cmd>Telescope git_status<CR>",
                desc = "Status (View)"
            }, {
                "<leader>s",
                group = "󰃻 Split"
            }, {
                "<leader>ss",
                "<cmd>split<CR>",
                desc = "Horizontal Split"
            }, {
                "<leader>vs",
                "<cmd>vsplit<CR>",
                desc = "Vertical Split"
            }, {
                "<leader>t",
                group = "󰨚 Toggle"
            }, {
                "<leader>tm",
                "<cmd>Telescope commands<CR>",
                desc = "Commands"
            }, {
                "<leader>to",
                "<cmd>SymbolsOutline<CR>",
                desc = "Symbols Outline"
            }, {
                "<leader>w",
                group = " Window"
            }, {
                "<leader>w=",
                "<C-w>=",
                desc = "Equal Size"
            }, {
                "<leader>wH",
                "<C-w>H",
                desc = "Move Window Left"
            }, {
                "<leader>wJ",
                "<C-w>J",
                desc = "Move Window Down"
            }, {
                "<leader>wK",
                "<C-w>K",
                desc = "Move Window Up"
            }, {
                "<leader>wL",
                "<C-w>L",
                desc = "Move Window Right"
            }, {
                "<leader>w_",
                "<C-w>_",
                desc = "Max Height"
            }, {
                "<leader>wh",
                "<C-w>h",
                desc = "Focus Left Window"
            }, {
                "<leader>wj",
                "<C-w>j",
                desc = "Focus Lower Window"
            }, {
                "<leader>wk",
                "<C-w>k",
                desc = "Focus Upper Window"
            }, {
                "<leader>wl",
                "<C-w>l",
                desc = "Focus Right Window"
            }, {
                "<leader>wo",
                "<cmd>only<CR>",
                desc = "Only Window"
            }, {
                "<leader>ww",
                "<cmd>close<CR>",
                desc = "Close Window"
            }})
        end
    })

    require("lazy").setup(specs)
    module_loader.setup_modules(module_system)
end

local function init()
    local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
    vim.opt.rtp:prepend(init_dir)

    require('common')
    setup_package_manager()
    setup_settings()

    setup_neovim_settings()
    setup_keybindings()
    setup_plugins()
end

init()
