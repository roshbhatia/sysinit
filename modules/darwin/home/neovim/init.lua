local config_path = vim.fn.stdpath("config")
package.path = package.path .. ";" .. config_path .. "/?.lua" .. ";" .. config_path .. "/lua/?.lua"
local plugin_manager = require("sysinit.pkg.plugin_manager")

vim.api.nvim_set_keymap("n", "q", "<Nop>", {
	noremap = true,
	silent = true,
})

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", {
	noremap = true,
	silent = true,
})

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<leader>w", ":q<CR>", {
	noremap = true,
	silent = true,
	desc = "Buffer: Close",
})

vim.keymap.set("n", "<leader>bn", "<cmd>bnext<CR>", {
	noremap = true,
	silent = true,
	desc = "Buffer: Next",
})

vim.keymap.set("n", "<leader>nn", function()
	if vim.wo.relativenumber then
		vim.wo.relativenumber = false
		vim.wo.number = true
	else
		vim.wo.relativenumber = true
		vim.wo.number = true
	end
end, {
	noremap = true,
	silent = true,
	desc = "Editor: Toggle line numbers",
})

vim.o.clipboard = "unnamedplus"
vim.opt.mouse = "a"

vim.opt.number = true
vim.opt.cursorline = false
vim.opt.signcolumn = "yes"

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

vim.opt.termguicolors = true

vim.opt.showmode = true
vim.opt.foldenable = true
vim.opt.foldlevel = 99

vim.opt.pumheight = 10
vim.opt.cmdheight = 0
vim.opt.laststatus = 3
vim.opt.timeoutlen = 500
vim.opt.updatetime = 300

vim.opt.number = true

vim.opt.shortmess:append("c")
vim.opt.completeopt = { "menuone", "noselect" }

vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

vim.env.PATH = vim.fn.getenv("PATH")

vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.o.autoread = true

plugin_manager.setup_package_manager()

local right_click = require("sysinit.pkg.right-click-menu")
right_click.add({
	editor_menu = {
		{
			id = "CodeEditor",
			label = "Cut",
			command = '"+x',
		},
		{
			id = "CodeEditor",
			label = "Copy",
			command = '"+y',
		},
		{
			id = "CodeEditor",
			label = "Paste",
			command = '"+p',
		},
		right_click.separator("CodeEditor"),
		{
			id = "CodeEditor",
			label = "Select All",
			command = "ggVG",
		},
	},
})

local plugins = {
	require("sysinit.plugins.debugger.dap"),
	require("sysinit.plugins.debugger.dap-ui"),
	require("sysinit.plugins.editor.comment"),
	require("sysinit.plugins.editor.formatter"),
	require("sysinit.plugins.editor.hlchunk"),
	require("sysinit.plugins.editor.hop"),
	require("sysinit.plugins.editor.intellitab"),
	require("sysinit.plugins.editor.far"),
	require("sysinit.plugins.editor.render-markdown"),
	require("sysinit.plugins.editor.surround"),
	require("sysinit.plugins.file.diffview"),
	require("sysinit.plugins.file.editor"),
	require("sysinit.plugins.file.session"),
	require("sysinit.plugins.file.telescope"),
	require("sysinit.plugins.file.tree"),
	require("sysinit.plugins.git.blamer"),
	require("sysinit.plugins.git.client"),
	require("sysinit.plugins.git.fugitive"),
	require("sysinit.plugins.git.signs"),
	require("sysinit.plugins.intellicode.aider"),
	require("sysinit.plugins.intellicode.avante"),
	require("sysinit.plugins.intellicode.cmp-buffer"),
	require("sysinit.plugins.intellicode.cmp-cmdline"),
	require("sysinit.plugins.intellicode.cmp-git"),
	require("sysinit.plugins.intellicode.cmp-nvim-lsp"),
	require("sysinit.plugins.intellicode.cmp-nvim-lua"),
	require("sysinit.plugins.intellicode.cmp-path"),
	require("sysinit.plugins.intellicode.copilot-chat"),
	require("sysinit.plugins.intellicode.copilot-cmp"),
	require("sysinit.plugins.intellicode.copilot"),
	require("sysinit.plugins.intellicode.eagle"),
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
	require("sysinit.plugins.keymaps.which-key"),
	require("sysinit.plugins.kubernetes.crossplane"),
	require("sysinit.plugins.kubernetes.kubectl"),
	require("sysinit.plugins.library.image"),
	require("sysinit.plugins.library.nio"),
	require("sysinit.plugins.library.nui"),
	require("sysinit.plugins.ui.alpha"),
	require("sysinit.plugins.ui.devicons"),
	require("sysinit.plugins.ui.dressing"),
	require("sysinit.plugins.ui.live-command"),
	require("sysinit.plugins.ui.minimap"),
	require("sysinit.plugins.ui.scrollbar"),
	require("sysinit.plugins.ui.smart-splits"),
	require("sysinit.plugins.ui.snacks"),
	require("sysinit.plugins.ui.statusbar"),
	require("sysinit.plugins.ui.terminal"),
	require("sysinit.plugins.ui.theme"),
	require("sysinit.plugins.ui.wilder"),
}

plugin_manager.setup_plugins(plugins)
