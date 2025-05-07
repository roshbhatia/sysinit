--[[
======================================================
NEOVIM CONFIGURATION (init.lua)
======================================================
A comprehensive Neovim configuration with extensive plugin
support for UI, editing, file management, Git, and LSP.
======================================================
--]]

-- Import core modules
local options = require('sysinit.pkg.options')       -- Options module (not used directly)
local plugin_manager = require('sysinit.pkg.plugin_manager') -- Plugin management system

-- Configure Lua's package path to include Neovim's config directories
local config_path = vim.fn.stdpath('config')
package.path = package.path .. ";" .. config_path .. "/?.lua" .. ";" .. config_path .. "/lua/?.lua"

----------------------------------------------------------
-- KEY MAPPINGS
----------------------------------------------------------

-- Disable 'q' in normal mode to prevent accidental macro recording
vim.api.nvim_set_keymap('n', 'q', '<Nop>', {
    noremap = true,
    silent = true
})

-- Clear space key functionality for use as leader
vim.keymap.set({"n", "v"}, "<Space>", "<Nop>", {
    noremap = true,
    silent = true
})
-- Set leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Keep : as command mode entry
vim.keymap.set("n", ":", ":", {
    noremap = true,
    desc = "Command mode"
})

-- Navigation improvements - center cursor after jumping
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

-- Terminal escape mapping
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
    noremap = true,
    silent = true
})

-- Window navigation with Ctrl+hjkl
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

-- File explorer toggle (both Alt and Cmd for cross-platform)
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

-- Toggle Copilot Chat
vim.keymap.set("n", "<A-D-jkb>", "<cmd>CopilotChatToggle<CR>", {
    noremap = true,
    silent = true,
    desc = "Toggle Copilot Chat"
})

-- Hop navigation (quick motion)
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

-- Comment toggling (Cmd+/ similar to many editors)
vim.keymap.set("n", "<D-/>", "<Plug>(comment_toggle_linewise_current)", {
    desc = "Toggle comment"
})
vim.keymap.set("v", "<D-/>", "<Plug>(comment_toggle_linewise_visual)", {
    desc = "Toggle comment"
})

-- Quick buffer switching with Ctrl+number
for i = 1, 9 do
    vim.keymap.set("n", "<C-" .. i .. ">", "<cmd>buffer " .. i .. "<CR>", {
        noremap = true,
        silent = true,
        desc = "Switch to buffer " .. i
    })
end

-- Common editor commands (macOS style)
-- Save file
vim.keymap.set({"n", "i", "v"}, "<D-s>", "<cmd>w<CR>", {
    noremap = true,
    silent = true,
    desc = "Save file"
})

-- Close buffer or quit
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

-- New file
vim.keymap.set({"n", "i", "v"}, "<D-n>", "<cmd>enew<CR>", {
    noremap = true,
    silent = true,
    desc = "New file"
})

-- Clipboard operations
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

-- Undo/Redo
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

-- Select all
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

-- Find operations
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

-- Find in files (grep)
vim.keymap.set("n", "<D-S-f>", "<cmd>Telescope live_grep<CR>", {
    noremap = true,
    silent = true,
    desc = "Find in files"
})

-- Quick file open
vim.keymap.set("n", "<D-p>", "<cmd>Telescope find_files<CR>", {
    noremap = true,
    silent = true,
    desc = "Quick open"
})

-- Command palette
vim.keymap.set("n", "<D-S-p>", "<cmd>Telescope commands<CR>", {
    noremap = true,
    silent = true,
    desc = "Command palette"
})

-- Duplicate find mapping (appears to be redundant)
vim.keymap.set({"n", "i"}, "<D-f>", "/", {
    noremap = true,
    desc = "Find"
})

----------------------------------------------------------
-- EDITOR SETTINGS
----------------------------------------------------------

-- Clipboard and mouse integration
vim.opt.clipboard = "unnamedplus"   -- Use system clipboard
vim.opt.mouse = "a"                 -- Enable mouse in all modes

-- Line numbers and sign column
vim.opt.number = true               -- Show line numbers
vim.opt.signcolumn = "number"       -- Show signs in the number column

-- Search settings
vim.opt.hlsearch = true             -- Highlight search results
vim.opt.incsearch = true            -- Show incremental search results
vim.opt.ignorecase = true           -- Case insensitive search...
vim.opt.smartcase = true            -- ...unless capital letters are used

-- Indentation and whitespace
vim.opt.expandtab = true            -- Convert tabs to spaces
vim.opt.shiftwidth = 2              -- Number of spaces for indentation
vim.opt.tabstop = 2                 -- Number of spaces for tab
vim.opt.smartindent = true          -- Auto indent new lines
vim.opt.wrap = true                 -- Wrap long lines
vim.opt.linebreak = true            -- Break lines at word boundaries
vim.opt.breakindent = true          -- Maintain indentation on wrapped lines

-- Split behavior
vim.opt.splitbelow = true           -- Open horizontal splits below
vim.opt.splitright = true           -- Open vertical splits to the right

-- Performance and UX settings
vim.opt.updatetime = 100            -- Faster update time for better responsiveness
vim.opt.timeoutlen = 300            -- Time to wait for mapped sequence to complete
vim.opt.scrolloff = 8               -- Min number of lines above/below cursor
vim.opt.sidescrolloff = 8           -- Min number of columns left/right of cursor
vim.opt.mouse = "a"                 -- Enable mouse in all modes (duplicate)

-- UI options
vim.opt.number = true               -- Show line numbers (duplicate)
vim.opt.cursorline = true           -- Highlight current line
vim.opt.signcolumn = "yes"          -- Always show sign column
vim.opt.termguicolors = true        -- True color support
vim.opt.showmode = true             -- Show current mode
vim.opt.foldenable = true           -- Enable folding
vim.opt.foldlevel = 99              -- Open all folds by default

-- Additional UI settings
vim.opt.pumheight = 10              -- Max items in popup menu
vim.opt.cmdheight = 1               -- Command line height
vim.opt.showtabline = 2             -- Always show tab line
vim.opt.timeoutlen = 500            -- Time to wait for keymap sequence (duplicate)
vim.opt.updatetime = 300            -- Faster update time (duplicate)
vim.opt.laststatus = 3              -- Global status line

-- Cursor appearance by mode
vim.opt.guicursor = {
    "n-v-c:block-Cursor/lCursor",                                      -- Block cursor in normal, visual, command modes
    "i:ver25-blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",      -- Blinking vertical line in insert mode
    "r-cr-o:hor20-Cursor/lCursor",                                     -- Horizontal line in replace modes
    "a:blinkwait700-blinkoff400-blinkon250"                            -- Global blinking settings
}

-- Completion behavior
vim.opt.shortmess:append("c")                -- Don't show completion messages
vim.opt.completeopt = {"menuone", "noselect"} -- Completion menu options

-- Visual elements
vim.opt.fillchars:append({
    eob = " ",       -- Hide end-of-buffer ~ markers
    vert = "│",      -- Vertical split separator
    fold = "⤷"       -- Folding indicator
})

-- Folding using treesitter
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- Environment settings
vim.env.PATH = vim.fn.getenv("PATH")        -- Preserve PATH from environment

-- Session management
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

----------------------------------------------------------
-- PLUGIN SETUP
----------------------------------------------------------

-- Initialize plugin system and load all plugins
plugin_manager.setup_package_manager()
plugin_manager.setup_plugins({
    -- UI components
    require("sysinit.plugins.ui.notifications"),
    require("sysinit.plugins.ui.live-command"),
    require("sysinit.plugins.ui.alpha"),
    require("sysinit.plugins.ui.devicons"),
    require("sysinit.plugins.ui.minimap"),
    require("sysinit.plugins.ui.nui"),
    require("sysinit.plugins.ui.scrollbar"),
    require("sysinit.plugins.ui.smart-splits"),
    require("sysinit.plugins.ui.statusbar"),
    require("sysinit.plugins.ui.tab"),
    require("sysinit.plugins.ui.theme"),
    require("sysinit.plugins.ui.transparent"),
    
    -- Editor enhancements
    require("sysinit.plugins.editor.hop"),
    require("sysinit.plugins.keymaps"),
    require("sysinit.plugins.editor.comment"),
    require("sysinit.plugins.editor.commentstring"),
    require("sysinit.plugins.editor.formatter"),
    require("sysinit.plugins.editor.ibl"),
    
    -- File handling
    require("sysinit.plugins.file.diffview"),
    require("sysinit.plugins.file.editor"),
    require("sysinit.plugins.file.session"),
    require("sysinit.plugins.file.telescope"),
    require("sysinit.plugins.ui.dressing"),
    require("sysinit.plugins.file.tree"),
    
    -- Git integration
    require("sysinit.plugins.git.blame"),
    require("sysinit.plugins.git.client"),
    require("sysinit.plugins.git.octo"),
    require("sysinit.plugins.git.fugitive"),
    require("sysinit.plugins.git.signs"),
    
    -- Intellicode/LSP/Completion
    require("sysinit.plugins.intellicode.avante"),
    require("sysinit.plugins.intellicode.cmp-buffer"),
    require("sysinit.plugins.intellicode.cmp-cmdline"),
    require("sysinit.plugins.intellicode.cmp-git"),
    require("sysinit.plugins.intellicode.cmp-nvim-lsp"),
    require("sysinit.plugins.intellicode.cmp-nvim-lua"),
    require("sysinit.plugins.intellicode.cmp-path"),
    require("sysinit.plugins.intellicode.copilot-cmp"),
    require("sysinit.plugins.intellicode.copilot"),
    require("sysinit.plugins.intellicode.copilot-chat"),
    require("sysinit.plugins.intellicode.schemastore"),
    require("sysinit.plugins.intellicode.friendly-snippets"),
    require("sysinit.plugins.intellicode.guess-indent"),
    require("sysinit.plugins.intellicode.img-clip"),
    require("sysinit.plugins.intellicode.linters"),
    require("sysinit.plugins.intellicode.luasnip"),
    require("sysinit.plugins.intellicode.mason-lspconfig"),
    require("sysinit.plugins.intellicode.mason"),
    require("sysinit.plugins.intellicode.nvim-autopairs"),
    require("sysinit.plugins.intellicode.nvim-cmp"),
    require("sysinit.plugins.intellicode.nvim-lspconfig"),
    require("sysinit.plugins.intellicode.outline"),
    require("sysinit.plugins.editor.render-markdown"),
    require("sysinit.plugins.intellicode.sort"),
    require("sysinit.plugins.intellicode.trailspace"),
    require("sysinit.plugins.intellicode.treesitter-textobjects"),
    require("sysinit.plugins.intellicode.treesitter"),
    require("sysinit.plugins.intellicode.trouble"),
    
    -- Debugging
    require("sysinit.plugins.debugger.dap")
})
