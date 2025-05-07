local plugin_manager = require('sysinit.pkg.plugin_manager')

local config_path = vim.fn.stdpath('config')
package.path = package.path .. ";" .. config_path .. "/?.lua" .. ";" .. config_path .. "/lua/?.lua"

-- Disable 'q' in normal mode to avoid accidental macro recordings
vim.api.nvim_set_keymap('n', 'q', '<Nop>', {
    noremap = true,
    silent = true
})

-- Disable Space key to use as <Leader> prefix
vim.keymap.set({"n", "v"}, "<Space>", "<Nop>", {
    noremap = true,
    silent = true
})
-- Set leader key. Space is unmapped above to use as <Leader> prefix for custom shortcuts.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Keep ':' mapping for entering command-line mode
vim.keymap.set("n", ":", ":", {
    noremap = true,
    desc = "Command mode"
})

-- Scrolling: page down and center cursor
vim.keymap.set("n", "<C-d>", "<C-d>zz", {
    noremap = true,
    silent = true
})
-- Scrolling: page up and center cursor
vim.keymap.set("n", "<C-u>", "<C-u>zz", {
    noremap = true,
    silent = true
})
-- Search: next match, center and unfold
vim.keymap.set("n", "n", "nzzzv", {
    noremap = true,
    silent = true
})
-- Search: previous match, center and unfold
vim.keymap.set("n", "N", "Nzzzv", {
    noremap = true,
    silent = true
})
-- Terminal: double Esc to exit to Normal mode
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
    noremap = true,
    silent = true
})

-- Window nav: move to left split with Ctrl+h
vim.keymap.set("n", "<C-h>", "<C-w>h", {
    noremap = true,
    silent = true,
    desc = "Move to left window"
})

-- Window nav: move to lower split with Ctrl+j
vim.keymap.set("n", "<C-j>", "<C-w>j", {
    noremap = true,
    silent = true,
    desc = "Move to lower window"
})

-- Window nav: move to upper split with Ctrl+k
vim.keymap.set("n", "<C-k>", "<C-w>k", {
    noremap = true,
    silent = true,
    desc = "Move to upper window"
})

-- Window nav: move to right split with Ctrl+l
vim.keymap.set("n", "<C-l>", "<C-w>l", {
    noremap = true,
    silent = true,
    desc = "Move to right window"
})

-- File explorer: toggle Neotree (Alt+b)
vim.keymap.set("n", "<A-b>", "<cmd>Neotree toggle<CR>", {
    noremap = true,
    silent = true,
    desc = "Toggle file explorer"
})

-- File explorer: toggle Neotree (Command+b)
vim.keymap.set("n", "<D-b>", "<cmd>Neotree toggle<CR>", {
    noremap = true,
    silent = true,
    desc = "Toggle file explorer"
})

-- AI: Toggle GitHub Copilot Chat
vim.keymap.set("n", "<A-D-jkb>", "<cmd>CopilotChatToggle<CR>", {
    noremap = true,
    silent = true,
    desc = "Toggle Copilot Chat"
})

-- Motion: Hop plugin – jump to word (Shift+Enter) in normal mode
vim.keymap.set("n", "<S-CR>", "<cmd>HopWord<CR>", {
    noremap = true,
    silent = true,
    desc = "Hop to word"
})

-- Motion: Hop plugin – jump to word (Shift+Enter) in insert mode
vim.keymap.set("i", "<S-CR>", "<Esc><cmd>HopWord<CR>", {
    noremap = true,
    silent = true,
    desc = "Hop to word"
})

-- Comment: Toggle comment on current line (Cmd + /)
vim.keymap.set("n", "<D-/>", "<Plug>(comment_toggle_linewise_current)", {
    desc = "Toggle comment"
})

-- Comment: Toggle comment on selection (Cmd + /)
vim.keymap.set("v", "<D-/>", "<Plug>(comment_toggle_linewise_visual)", {
    desc = "Toggle comment"
})

-- Buffers: Quick switch to buffer N using Ctrl + N
for i = 1, 9 do
    vim.keymap.set("n", "<C-" .. i .. ">", "<cmd>buffer " .. i .. "<CR>", {
        noremap = true,
        silent = true,
        desc = "Switch to buffer " .. i
    })
end

-- File: Save current buffer (Cmd + S)
vim.keymap.set({"n", "i", "v"}, "<D-s>", "<cmd>w<CR>", {
    noremap = true,
    silent = true,
    desc = "Save file"
})

-- File: Close current buffer or quit if last (Cmd + W)
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

-- File: New empty buffer (Cmd + N)
vim.keymap.set({"n", "i", "v"}, "<D-n>", "<cmd>enew<CR>", {
    noremap = true,
    silent = true,
    desc = "New file"
})

-- Clipboard: Copy selection to system clipboard (Cmd + C)
vim.keymap.set("v", "<D-c>", '"+y', {
    noremap = true,
    silent = true,
    desc = "Copy to clipboard"
})

-- Clipboard: Copy current line in normal/insert mode (Cmd + C)
vim.keymap.set({"n", "i"}, "<D-c>", '<cmd>let @+=@"<CR>', {
    noremap = true,
    silent = true,
    desc = "Copy to clipboard"
})

-- Clipboard: Cut selection to system clipboard (Cmd + X)
vim.keymap.set("v", "<D-x>", '"+d', {
    noremap = true,
    silent = true,
    desc = "Cut to clipboard"
})

-- Clipboard: Paste from system clipboard (Cmd + V)
vim.keymap.set({"n", "i", "v"}, "<D-p>", '"+p', {
    noremap = true,
    silent = true,
    desc = "Paste from clipboard"
})

-- Undo/Redo: Cmd + Z / Cmd + Shift + Z
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

-- Select All: Cmd + A (normal/insert mode aware)
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

-- Search: Cmd + F (enters search mode)
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

-- Search: Cmd + Shift + F to live grep files
vim.keymap.set("n", "<D-S-f>", "<cmd>Telescope live_grep<CR>", {
    noremap = true,
    silent = true,
    desc = "Find in files"
})

-- Search: Cmd + P to open files via Telescope
vim.keymap.set("n", "<D-p>", "<cmd>Telescope find_files<CR>", {
    noremap = true,
    silent = true,
    desc = "Quick open"
})

-- Search: Cmd + Shift + P to open command palette
vim.keymap.set("n", "<D-S-p>", "<cmd>Telescope commands<CR>", {
    noremap = true,
    silent = true,
    desc = "Command palette"
})

-- Redundant but explicit search shortcut
vim.keymap.set({"n", "i"}, "<D-f>", "/", {
    noremap = true,
    desc = "Find"
})

-- === Options === --

-- Clipboard & mouse
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"

-- Line numbers and sign column
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"

-- Search settings
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

-- Wrapping
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

-- Window splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Performance
vim.opt.updatetime = 100
vim.opt.timeoutlen = 300
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- UI visuals
vim.opt.termguicolors = true
vim.opt.showmode = true
vim.opt.foldenable = true
vim.opt.foldlevel = 99

-- Popup/Command/Status line
vim.opt.pumheight = 10
vim.opt.cmdheight = 1
vim.opt.showtabline = 2
vim.opt.timeoutlen = 500
vim.opt.updatetime = 300
vim.opt.laststatus = 3

vim.opt.guicursor = {"n-v-c:block-Cursor/lCursor", -- Block cursor in normal, visual, and command modes
"i:ver25-blinkwait700-blinkoff400-blinkon250-Cursor/lCursor", -- Blinking vertical line in insert mode
"r-cr-o:hor20-Cursor/lCursor", -- Horizontal line cursor in replace, command-line replace, and operator-pending modes
"a:blinkwait700-blinkoff400-blinkon250" -- Global blinking settings for all modes
}

-- Completion settings
vim.opt.shortmess:append("c")
vim.opt.completeopt = {"menuone", "noselect"}

-- Fill characters
vim.opt.fillchars:append({
    eob = " ",
    vert = "│",
    fold = "⤷"
})

-- Folding with treesitter
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- Environment setup
vim.env.PATH = vim.fn.getenv("PATH")

-- Session persistence
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

plugin_manager.setup_package_manager()

local plugins = {require("sysinit.plugins.ui.notifications"), require("sysinit.plugins.ui.live-command"),
                 require("sysinit.plugins.ui.alpha"), require("sysinit.plugins.ui.devicons"),
                 require("sysinit.plugins.ui.minimap"), require("sysinit.plugins.ui.nui"),
                 require("sysinit.plugins.ui.scrollbar"), require("sysinit.plugins.ui.smart-splits"),
                 require("sysinit.plugins.ui.statusbar"), require("sysinit.plugins.ui.tab"),
                 require("sysinit.plugins.ui.theme"), require("sysinit.plugins.ui.transparent"),
                 require("sysinit.plugins.ui.dressing"), require("sysinit.plugins.editor.hop"),
                 require("sysinit.plugins.keymaps.wf"), require("sysinit.plugins.editor.comment"),
                 require("sysinit.plugins.editor.commentstring"), require("sysinit.plugins.editor.formatter"),
                 require("sysinit.plugins.editor.ibl"), require("sysinit.plugins.editor.render-markdown"),
                 require("sysinit.plugins.file.diffview"), require("sysinit.plugins.file.editor"),
                 require("sysinit.plugins.file.session"), require("sysinit.plugins.file.telescope"),
                 require("sysinit.plugins.file.tree"), require("sysinit.plugins.git.blame"),
                 require("sysinit.plugins.git.client"), require("sysinit.plugins.git.octo"),
                 require("sysinit.plugins.git.fugitive"), require("sysinit.plugins.git.signs"),
                 require("sysinit.plugins.intellicode.avante"), require("sysinit.plugins.intellicode.cmp-buffer"),
                 require("sysinit.plugins.intellicode.cmp-cmdline"), require("sysinit.plugins.intellicode.cmp-git"),
                 require("sysinit.plugins.intellicode.cmp-nvim-lsp"),
                 require("sysinit.plugins.intellicode.cmp-nvim-lua"), require("sysinit.plugins.intellicode.cmp-path"),
                 require("sysinit.plugins.intellicode.copilot-cmp"), require("sysinit.plugins.intellicode.copilot"),
                 require("sysinit.plugins.intellicode.copilot-chat"),
                 require("sysinit.plugins.intellicode.schemastore"),
                 require("sysinit.plugins.intellicode.friendly-snippets"),
                 require("sysinit.plugins.intellicode.guess-indent"), require("sysinit.plugins.intellicode.img-clip"),
                 require("sysinit.plugins.intellicode.linters"), require("sysinit.plugins.intellicode.luasnip"),
                 require("sysinit.plugins.intellicode.mason-lspconfig"), require("sysinit.plugins.intellicode.mason"),
                 require("sysinit.plugins.intellicode.nvim-autopairs"), require("sysinit.plugins.intellicode.nvim-cmp"),
                 require("sysinit.plugins.intellicode.nvim-lspconfig"), require("sysinit.plugins.intellicode.outline"),
                 require("sysinit.plugins.intellicode.sort"), require("sysinit.plugins.intellicode.trailspace"),
                 require("sysinit.plugins.intellicode.treesitter-textobjects"),
                 require("sysinit.plugins.intellicode.treesitter"), require("sysinit.plugins.intellicode.trouble"),
                 require("sysinit.plugins.debugger.dap")}

-- Setup plugins
plugin_manager.setup_plugins(plugins)
