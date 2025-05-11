local M = {}

-- Register all basic editor options
function M.register_options()
	-- Clipboard
	vim.o.clipboard = "unnamedplus"

	-- Editor behavior
	vim.opt.mouse = "a"
	vim.opt.number = true
	vim.opt.cursorline = false
	vim.opt.signcolumn = "yes:2"

	-- Search options
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

	-- Split behavior
	vim.opt.splitbelow = true
	vim.opt.splitright = true

	-- Performance and timing
	vim.opt.updatetime = 100
	vim.opt.timeoutlen = 300

	-- Scroll options
	vim.opt.scrolloff = 8
	vim.opt.sidescrolloff = 8

	-- UI options
	vim.opt.termguicolors = true
	vim.opt.showmode = true

	-- Folding
	vim.opt.foldenable = true
	vim.opt.foldlevel = 99
	vim.wo.foldmethod = "expr"
	vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

	-- Completion
	vim.opt.pumheight = 10
	vim.opt.cmdheight = 0
	vim.opt.cmdwinheight = 1
	vim.opt.laststatus = 3
	vim.opt.completeopt = { "menu", "menuone", "fuzzy", "preview" }

	-- Environment
	vim.env.PATH = vim.fn.getenv("PATH")
	vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
	vim.o.autoread = true
end

-- Register leader key (should be called before keybindings)
function M.register_leader()
	vim.g.mapleader = " "
	vim.g.maplocalleader = " "
end

-- Register all basic keybindings
function M.register_keybindings()
	-- Disable recording
	vim.api.nvim_set_keymap("n", "q", "<Nop>", {
		noremap = true,
		silent = true,
	})

	-- Space as leader key
	vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", {
		noremap = true,
		silent = true,
	})

	-- MacOS clipboard integration
	vim.keymap.set("n", "<D-c>", '"+y', { silent = true, noremap = true })
	vim.keymap.set("v", "<D-c>", '"+y', { silent = true, noremap = true })
	vim.keymap.set("n", "<D-v>", '"+p', { silent = true, noremap = true })
	vim.keymap.set("v", "<D-v>", '"+p', { silent = true, noremap = true })
	vim.keymap.set("i", "<D-v>", "<C-r>+", { silent = true, noremap = true })
	vim.keymap.set("c", "<D-v>", "<C-r>+", { silent = true, noremap = true })
	vim.keymap.set("n", "<D-x>", '"+d', { silent = true, noremap = true })
	vim.keymap.set("v", "<D-x>", '"+d', { silent = true, noremap = true })
	vim.keymap.set("n", "<D-p>", '"+p', { silent = true, noremap = true })
	vim.keymap.set("v", "<D-p>", '"+p', { silent = true, noremap = true })

	-- Buffer management
	vim.keymap.set("n", "<leader>w", ":wq!<CR>", {
		noremap = true,
		silent = true,
		desc = " Write and close",
	})

	vim.keymap.set("n", "<leader>bn", "<cmd>bnext<CR>", {
		noremap = true,
		silent = true,
		desc = " Next",
	})

	vim.keymap.set("n", "<leader>bp", "<cmd>bprev<CR>", {
		noremap = true,
		silent = true,
		desc = " Previous",
	})

	vim.keymap.set("n", "<leader>Q", ":qa!<CR>", {
		noremap = true,
		silent = true,
		desc = " Quit",
	})

	vim.keymap.set("n", "<leader>en", function()
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
		desc = " Toggle absolute & relative",
	})
end

return M
