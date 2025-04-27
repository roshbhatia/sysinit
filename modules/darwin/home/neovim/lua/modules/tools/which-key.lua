local M = {}

M.plugins = {{
    "folke/which-key.nvim",
    lazy = VeryLazy,
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
            "<leader>a",
            group = " AI"
        }, {
            "<leader>ac",
            "<cmd>CopilotChatToggle<CR>",
            desc = "Toggle Chat"
        }, {
            "<leader>ad",
            "<cmd>CopilotChatDocumentThis<CR>",
            desc = "Generate Docs"
        }, {
            "<leader>ao",
            "<cmd>CopilotChatOptimizeCode<CR>",
            desc = "Optimize"
        }, {
            "<leader>ar",
            "<cmd>CopilotChatRefactorCode<CR>",
            desc = "Refactor"
        }, {
            "<leader>af",
            "<cmd>CopilotChatFix<CR>",
            desc = "Fix Code"
        }, {
            "<leader>ae",
            "<cmd>CopilotChatExplain<CR>",
            desc = "Explain"
        }, {
            "<leader>at",
            "<cmd>CopilotChatTests<CR>",
            desc = "Generate Tests"
        }, {
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
            "<leader>sv",
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
}}

return M
