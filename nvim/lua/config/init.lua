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
    'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons', {
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
    {
        'lukas-reineke/indent-blankline.nvim',
        main = 'ibl',
        ---@module "ibl"
        ---@type ibl.config
        opts = {}
    }, -- Indent guide lines
    'terrortylor/nvim-comment', -- Easy commenting
    {
        'akinsho/toggleterm.nvim', -- Better terminal
        version = '*',
        config = true
    }, -- Kubectl support
    {
        'Ramilito/kubectl.nvim', -- Kubectl integration
        dependencies = {'nvim-lua/plenary.nvim'}
    }
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
        {name = 'nvim_lsp'}, {name = 'luasnip'}, {name = 'buffer'},
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
require('indent_blankline').setup({
    show_current_context = true,
    show_current_context_start = true
})
require('toggleterm').setup({open_mapping = [[<c-\>]], direction = 'float'})

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

-- Default settings

if vim.v.argv == 0 then vim.cmd('autocmd VimEnter * StartifyStart') end
