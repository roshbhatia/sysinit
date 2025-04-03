-- Init lazy plugin manager
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        'git', 'clone', '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath
    })
end
vim.opt.rtp:prepend(lazypath)

-- Install external plugins
require('lazy').setup({
    {'kepano/flexoki-neovim', name = 'flexoki'}, 'lewis6991/gitsigns.nvim',
    -- 'nvim-treesitter/nvim-treesitter',
     'nvim-tree/nvim-web-devicons', {
        'nvim-tree/nvim-tree.lua',
        version = '*',
        lazy = false,
        after = {'nvim-tree/nvim-web-devicons'},
        dependencies = {'nvim-tree/nvim-web-devicons'},
        config = function() require('nvim-tree').setup {} end
    }, {
        'romgrk/barbar.nvim',
        dependencies = {
            'lewis6991/gitsigns.nvim', 'nvim-tree/nvim-web-devicons'
        },
        init = function() vim.g.barbar_auto_setup = false end,
        opts = {}
    }, 'jackguo380/vim-lsp-cxx-highlight', 'liuchengxu/vim-which-key',
    'mhinz/vim-startify', 'gorbit99/codewindow.nvim', 'gelguy/wilder.nvim',
    'bluz71/nvim-linefly', -- VSCode-like IDE features
    'neovim/nvim-lspconfig', -- LSP support
    'hrsh7th/nvim-cmp', -- Autocompletion
    'hrsh7th/cmp-nvim-lsp', -- LSP source for nvim-cmp
    'hrsh7th/cmp-buffer', -- Buffer source for nvim-cmp
    'hrsh7th/cmp-path', -- Path source for nvim-cmp
    'L3MON4D3/LuaSnip', -- Snippets engine
    'saadparwaiz1/cmp_luasnip', -- Snippets source for nvim-cmp
    'rafamadriz/friendly-snippets', -- Predefined snippets
    'onsails/lspkind.nvim', -- Add VS Code-like pictograms to completion menu
    'folke/trouble.nvim', -- Pretty diagnostics
    {
        'nvim-telescope/telescope.nvim', -- Fuzzy finder
        dependencies = {'nvim-lua/plenary.nvim'}
    }, 'simrat39/symbols-outline.nvim', -- Code outline/structure view
    {
        'folke/which-key.nvim', -- Better keybindings display
        event = 'VeryLazy',
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
        end
    }, 'windwp/nvim-autopairs', -- Auto pairing brackets
    'terrortylor/nvim-comment', -- Easy commenting
    {
        'akinsho/toggleterm.nvim', -- Better terminal
        version = '*',
        config = true
    }, -- Kubectl support
    {
        'Ramilito/kubectl.nvim', -- Kubectl integration
        dependencies = {'nvim-lua/plenary.nvim'}
    },
    -- New plugins for enhanced IDE functionality
    -- {
    --     'stevearc/aerial.nvim', -- Code outline with LSP symbols
    --     dependencies = {'nvim-treesitter/nvim-treesitter'}
    -- },
    -- { 'nvim-treesitter/nvim-treesitter-textobjects' }, -- Enhanced text objects
    { 'mhartington/formatter.nvim' }, -- Code formatting
    { 
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make'
    },
    { 
        'zbirenbaum/copilot.lua', -- GitHub Copilot integration
        event = 'InsertEnter',
        config = function()
            require('copilot').setup({
                suggestion = { enabled = false },
                panel = { enabled = false },
            })
        end
    },
    { 
        'zbirenbaum/copilot-cmp',
        config = function()
            require('copilot_cmp').setup()
        end
    },
    { 'f-person/git-blame.nvim' }, -- Git blame integration
    { 'mg979/vim-visual-multi' }, -- Multiple cursors
    -- { 'nvim-treesitter/nvim-treesitter-context' }, -- Show context at top of buffer
    { 
        'folke/todo-comments.nvim', -- Highlight and list TODO comments
        dependencies = {'nvim-lua/plenary.nvim'}
    },
    { 'sbdchd/neoformat' } -- Alternative formatter
}, {lazy = false, version = false})

-- Load configuration modules
local config_modules = {
    'general', 'barline', 'startify', 'nvim-tree', 'codewindow', 'wilder'
}

for _, module in ipairs(config_modules) do require('config.' .. module) end

-- LSP setup
local lspconfig = require('lspconfig')

-- Add your language servers here
-- Example for common languages:
-- lspconfig.tsserver.setup{}
-- lspconfig.pyright.setup{}
-- lspconfig.rust_analyzer.setup{}
-- lspconfig.gopls.setup{}

-- Autocompletion setup
local cmp = require('cmp')
local luasnip = require('luasnip')
local lspkind = require('lspkind')

require('luasnip.loaders.from_vscode').lazy_load()

cmp.setup({
    snippet = {expand = function(args) luasnip.lsp_expand(args.body) end},
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({select = true}),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, {'i', 's'}),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, {'i', 's'})
    }),
    sources = cmp.config.sources({
        {name = 'copilot'},
        {name = 'nvim_lsp'},
        {name = 'luasnip'},
        {name = 'buffer'},
        {name = 'path'}
    }),
    formatting = {
        format = lspkind.cmp_format({mode = 'symbol_text', maxwidth = 50})
    }
})

-- Set up other IDE features
require('nvim-autopairs').setup({})
require('nvim_comment').setup()
require('symbols-outline').setup()
require('trouble').setup()
require('toggleterm').setup({open_mapping = [[<c-\>]], direction = 'float'})

-- Treesitter setup
-- require('nvim-treesitter.configs').setup({
--     ensure_installed = "all",
--     highlight = { enable = true },
--     incremental_selection = { enable = true },
--     indent = { enable = true },
--     textobjects = {
--         select = {
--             enable = true,
--             lookahead = true,
--             keymaps = {
--                 ["af"] = "@function.outer",
--                 ["if"] = "@function.inner",
--                 ["ac"] = "@class.outer",
--                 ["ic"] = "@class.inner",
--             },
--         },
--     },
-- })

-- Aerial setup (Code outline)
require('aerial').setup({
    layout = {
        default_direction = "right",
        placement = "edge",
        width = 30,
    },
    keymaps = {
        ["<leader>to"] = "toggle",
    },
})

-- Formatting setup
require('formatter').setup({
    filetype = {
        javascript = {
            function()
                return {
                    exe = "prettier",
                    args = {"--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0))},
                    stdin = true
                }
            end
        },
        typescript = {
            function()
                return {
                    exe = "prettier",
                    args = {"--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0))},
                    stdin = true
                }
            end
        },
        python = {
            function()
                return {
                    exe = "black",
                    args = {"-"},
                    stdin = true
                }
            end
        },
        rust = {
            function()
                return {
                    exe = "rustfmt",
                    args = {"--emit=stdout"},
                    stdin = true
                }
            end
        },
        go = {
            function()
                return {
                    exe = "gofmt",
                    stdin = true
                }
            end
        },
    }
})

-- Format on save
vim.cmd([[augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost * FormatWrite
augroup END]])

-- Git blame setup
require('gitblame').setup({
    enabled = false,
})

-- Todo comments
require('todo-comments').setup()

-- Kubectl setup
require('kubectl').setup({
    -- Your kubectl config here
})

-- Define a custom command to open Startify
vim.cmd([[
  command! StartifyStart call StartifyStart()
  function StartifyStart()
    execute 'Startify'
  endfunction
]])

-- Helper to add a newline
vim.cmd([[
  function! AddNewLine()
    let save_cursor = getcurpos()
    call append(line('.'), '')
    call setpos('.', save_cursor)
  endfunction

  function! RemoveNewLine()
    let current_line = line('.')
    if current_line < line('$')
      execute 'normal! J'
    endif
  endfunction
]])

-- Neovim help command
vim.cmd([[
  command! NvimHelp !sh ~/.config/nvim/nvim-help.sh
  command! NvimHelpNav !sh ~/.config/nvim/nvim-help.sh nav
  command! NvimHelpCode !sh ~/.config/nvim/nvim-help.sh code
  command! NvimHelpEditor !sh ~/.config/nvim/nvim-help.sh editor
  command! NvimHelpGit !sh ~/.config/nvim/nvim-help.sh git
  command! NvimHelpCopilot !sh ~/.config/nvim/nvim-help.sh copilot
  command! NvimHelpK8s !sh ~/.config/nvim/nvim-help.sh k8s
]])

-- Define a command palette function
vim.cmd([[
  function! CommandPalette()
    call wilder#start_search()
  endfunction
  command! CommandPalette call CommandPalette()
]])

-- Keybindings
-- Map <F1> to open or close Startify
vim.api.nvim_set_keymap('n', '<F1>', ':StartifyStart<CR>',
                        {noremap = true, silent = true})

-- Map <F2> to open or close nvim-tree
vim.api.nvim_set_keymap('n', '<F2>', ':NvimTreeToggle<CR>',
                        {noremap = true, silent = true})

-- Telescope keybindings
vim.api.nvim_set_keymap('n', '<leader>ff', ':Telescope find_files<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>fg', ':Telescope live_grep<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>fb', ':Telescope buffers<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>fh', ':Telescope help_tags<CR>',
                        {noremap = true, silent = true})

-- LSP keybindings
vim.api.nvim_set_keymap('n', 'gd', ':lua vim.lsp.buf.definition()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'gr', ':lua vim.lsp.buf.references()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'gi', ':lua vim.lsp.buf.implementation()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'K', ':lua vim.lsp.buf.hover()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>rn', ':lua vim.lsp.buf.rename()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>ca', ':lua vim.lsp.buf.code_action()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>e',
                        ':lua vim.diagnostic.open_float()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>tt', ':TroubleToggle<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>so', ':SymbolsOutline<CR>',
                        {noremap = true, silent = true})

-- Format keybindings
vim.api.nvim_set_keymap('n', '<leader>fm', ':Format<CR>',
                        {noremap = true, silent = true})

-- Add/remove newline keybindings
vim.api.nvim_set_keymap('n', '<leader>nl', ':call AddNewLine()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>nld', ':call RemoveNewLine()<CR>',
                        {noremap = true, silent = true})

-- Git blame keybindings
vim.api.nvim_set_keymap('n', '<leader>gb', ':GitBlameToggle<CR>',
                        {noremap = true, silent = true})

-- Command palette
vim.api.nvim_set_keymap('n', '<leader>p', ':CommandPalette<CR>',
                        {noremap = true, silent = true})

-- Copilot keybindings
vim.api.nvim_set_keymap('n', '<leader>cc', ':Copilot toggle<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>cs', ':Copilot suggestion<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>cd', ':Copilot panel<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>cr', ':Copilot chat<CR>',
                        {noremap = true, silent = true})

-- Kubectl keybindings
vim.api.nvim_set_keymap('n', '<leader>kl',
                        ':lua require("kubectl").get_logs()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>kp',
                        ':lua require("kubectl").get_pods()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>kd',
                        ':lua require("kubectl").describe()<CR>',
                        {noremap = true, silent = true})

-- NvimHelp keybindings
vim.api.nvim_set_keymap('n', '<leader>h', ':NvimHelp<CR>',
                        {noremap = true, silent = false})

-- Default settings
if vim.v.argv == 0 then vim.cmd('autocmd VimEnter * StartifyStart') end