local config_path = vim.fn.stdpath("config")
package.path = package.path .. ";" .. config_path .. "/?.lua" .. ";" .. config_path .. "/lua/?.lua"
local plugin_manager = require("sysinit.pkg.plugin_manager")

-- Disable 'q' in normal mode to avoid accidental macro recordings
vim.api.nvim_set_keymap("n", "q", "<Nop>", {
	noremap = true,
	silent = true,
})

-- Disable Space key to use as <Leader> prefix
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", {
	noremap = true,
	silent = true,
})

-- Set leader key. Space is unmapped above to use as <Leader> prefix for custom shortcuts.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Search: next match, center and unfold
vim.keymap.set("n", "n", "nzzzv", {
	noremap = true,
	silent = true,
	desc = "Next search",
})
-- Search: previous match, center and unfold
vim.keymap.set("n", "N", "Nzzzv", {
	noremap = true,
	silent = true,
	desc = "Previous search",
})

-- File: Save current buffer (Cmd + S)
vim.keymap.set({ "n", "i", "v" }, "<D-s>", "<cmd>w<CR>", {
	noremap = true,
	silent = true,
	desc = "Save file",
})

-- File: New empty buffer (Cmd + N)
vim.keymap.set({ "n", "i", "v" }, "<D-n>", "<cmd>enew<CR>", {
	noremap = true,
	silent = true,
	desc = "New file",
})

-- Clipboard: Copy selection to system clipboard (Cmd + C)
vim.keymap.set("v", "<D-c>", '"+y', {
	noremap = true,
	silent = true,
	desc = "Copy to clipboard",
})

-- Clipboard: Copy current line in normal/insert mode (Cmd + C)
vim.keymap.set({ "n", "i" }, "<D-c>", '<cmd>let @+=@"<CR>', {
	noremap = true,
	silent = true,
	desc = "Copy to clipboard",
})

-- Clipboard: Cut selection to system clipboard (Cmd + X)
vim.keymap.set("v", "<D-x>", '"+d', {
	noremap = true,
	silent = true,
	desc = "Cut to clipboard",
})

-- Clipboard: Paste from system clipboard (Cmd + V)
vim.keymap.set({ "n", "i", "v" }, "<D-p>", '"+p', {
	noremap = true,
	silent = true,
	desc = "Paste from clipboard",
})

-- Undo/Redo: Cmd + Z / Cmd + Shift + Z
vim.keymap.set({ "n", "i" }, "<D-z>", "<cmd>undo<CR>", {
	noremap = true,
	silent = true,
	desc = "Undo",
})
vim.keymap.set({ "n", "i" }, "<D-S-z>", "<cmd>redo<CR>", {
	noremap = true,
	silent = true,
	desc = "Redo",
})

-- Select All: Cmd + A (normal/insert mode aware)
vim.keymap.set({ "n", "v", "i" }, "<D-a>", function()
	if vim.fn.mode() == "i" then
		return "<Esc>ggVG"
	else
		return "ggVG"
	end
end, {
	noremap = true,
	expr = true,
	desc = "Select all",
})

vim.keymap.set("n", "<leader>bd", ":q<CR>", {
	noremap = true,
	silent = true,
	desc = "Buffer: Close",
})

vim.keymap.set("n", "<leader>bD", ":bdelete<CR>", {
	noremap = true,
	silent = true,
	desc = "Buffer: Delete",
})

vim.keymap.set("n", "<leader>bn", "<cmd>bnext<CR>", {
	noremap = true,
	silent = true,
	desc = "Buffer: Next",
})

vim.keymap.set("n", "<leader>bp", "<cmd>bprevious<CR>", {
	noremap = true,
	silent = true,
	desc = "Buffer: Previous",
})

vim.keymap.set("n", "<leader>bl", "<cmd>buffers<CR>", {
	noremap = true,
	silent = true,
	desc = "Buffer: List",
})

vim.keymap.set("n", "<leader>bw", "<cmd>write<CR>", {
	noremap = true,
	silent = true,
	desc = "Buffer: Write",
})

vim.keymap.set("n", "<leader>bW", "<cmd>wall<CR>", {
	noremap = true,
	silent = true,
	desc = "Buffer: Write All",
})

vim.keymap.set("n", "<leader>bi", "<cmd>enew<CR>", {
	noremap = true,
	silent = true,
	desc = "Buffer: New (Init)",
})

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		vim.cmd("wincmd o")
	end,
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
vim.opt.laststatus = 2

-- Completion settings
vim.opt.shortmess:append("c")
vim.opt.completeopt = { "menuone", "noselect" }

-- Fill characters
vim.opt.fillchars:append({
	eob = " ",
	vert = "│",
	fold = "⤷",
})

-- Folding with treesitter
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Environment setup
vim.env.PATH = vim.fn.getenv("PATH")

-- Session persistence
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.o.autoread = true

plugin_manager.setup_package_manager()

local plugins = {
	require("sysinit.plugins.debugger.dap"),
	require("sysinit.plugins.editor.comment"),
	require("sysinit.plugins.editor.formatter"),
	require("sysinit.plugins.editor.hop"),
	require("sysinit.plugins.editor.ibl"),
	require("sysinit.plugins.editor.intellitab"),
	require("sysinit.plugins.editor.render-markdown"),
	require("sysinit.plugins.editor.surround"),
	require("sysinit.plugins.file.diffview"),
	require("sysinit.plugins.file.editor"),
	require("sysinit.plugins.file.session"),
	require("sysinit.plugins.file.telescope"),
	require("sysinit.plugins.file.tree"),
	require("sysinit.plugins.git.client"),
	require("sysinit.plugins.git.fugitive"),
	require("sysinit.plugins.git.octo"),
	require("sysinit.plugins.git.signs"),
	require("sysinit.plugins.intellicode.cmp-buffer"),
	require("sysinit.plugins.intellicode.cmp-cmdline"),
	require("sysinit.plugins.intellicode.cmp-git"),
	require("sysinit.plugins.intellicode.cmp-nvim-lsp"),
	require("sysinit.plugins.intellicode.cmp-nvim-lua"),
	require("sysinit.plugins.intellicode.cmp-path"),
	require("sysinit.plugins.intellicode.copilot-chat"),
	require("sysinit.plugins.intellicode.copilot-cmp"),
	require("sysinit.plugins.intellicode.copilot"),
	require("sysinit.plugins.intellicode.friendly-snippets"),
	require("sysinit.plugins.intellicode.guess-indent"),
	require("sysinit.plugins.intellicode.linters"),
	require("sysinit.plugins.intellicode.luasnip"),
	require("sysinit.plugins.intellicode.mason-lspconfig"),
	require("sysinit.plugins.intellicode.mason"),
	require("sysinit.plugins.intellicode.nvim-autopairs"),
	require("sysinit.plugins.intellicode.nvim-cmp"),
	require("sysinit.plugins.intellicode.nvim-lspconfig"),
	require("sysinit.plugins.intellicode.outline"),
	require("sysinit.plugins.intellicode.schemastore"),
	require("sysinit.plugins.intellicode.sort"),
	require("sysinit.plugins.intellicode.trailspace"),
	require("sysinit.plugins.intellicode.treesitter-textobjects"),
	require("sysinit.plugins.intellicode.treesitter"),
	require("sysinit.plugins.intellicode.trouble"),
	require("sysinit.plugins.keymaps.wf"),
	require("sysinit.plugins.kubernetes.crossplane"),
	require("sysinit.plugins.kubernetes.kubectl"),
	require("sysinit.plugins.library.nio"),
	require("sysinit.plugins.library.nui"),
	require("sysinit.plugins.ui.alpha"),
	require("sysinit.plugins.ui.border"),
	require("sysinit.plugins.ui.cmdline"),
	require("sysinit.plugins.ui.devicons"),
	require("sysinit.plugins.ui.dressing"),
	require("sysinit.plugins.ui.live-command"),
	require("sysinit.plugins.ui.minimap"),
	require("sysinit.plugins.ui.scrollbar"),
	require("sysinit.plugins.ui.smart-splits"),
	require("sysinit.plugins.ui.snacks"),
	require("sysinit.plugins.ui.statusbar"),
	require("sysinit.plugins.ui.tab"),
	require("sysinit.plugins.ui.terminal"),
	require("sysinit.plugins.ui.theme"),
	require("sysinit.plugins.ui.transparent"),
}

plugin_manager.setup_plugins(plugins)
