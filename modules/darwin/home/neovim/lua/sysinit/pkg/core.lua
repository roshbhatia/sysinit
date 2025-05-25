local M = {}

-- Register all basic editor options
function M.register_options()
	-- Environment
	vim.env.PATH = vim.fn.getenv("PATH")

	-- Editor behavior
	vim.opt.mouse = "a"
	vim.opt.number = true
	vim.opt.signcolumn = "yes:2"
	vim.opt.fillchars:append({ eob = " " })
	vim.opt.cursorline = false
	vim.opt.spell = false

	-- Search options
	vim.opt.hlsearch = true
	vim.opt.incsearch = true
	vim.opt.ignorecase = true
	vim.opts.incommand = "nosplit"

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

	-- Enable autoread
	vim.o.autoread = true

	vim.api.nvim_create_autocmd("FocusGained", {
		desc = "Reload files from disk when we focus vim",
		pattern = "*",
		command = "if getcmdwintype() == '' | checktime | endif",
		group = aug,
	})
	vim.api.nvim_create_autocmd("BufEnter", {
		desc = "Every time we enter an unmodified buffer, check if it changed on disk",
		pattern = "*",
		command = "if &buftype == '' && !&modified && expand('%') != '' | exec 'checktime ' . expand('<abuf>') | endif",
		group = aug,
	})

	-- Undo directory for more persisted undo's
	local undodir = vim.fn.stdpath("cache") .. "/undo"
	if vim.fn.isdirectory(undodir) == 0 then
		vim.fn.mkdir(undodir, "p")
	end
	vim.opt.undodir = undodir
	vim.opt.undofile = true
end

-- Register leader key (should be called before keybindings)
function M.register_leader()
	vim.g.mapleader = " "
	vim.g.maplocalleader = " "
end

-- Register all basic keybindings
function M.register_keybindings()
	-- Explicit redo key
	vim.api.nvim_set_keymap("n", "U", "<cmd>later<cr>", {
		noremap = true,
		silent = true,
	})

	-- Disable recording
	vim.api.nvim_set_keymap("n", "q", "<Nop>", {
		noremap = true,
		silent = true,
	})

	-- Disable marks (we use global marks)
	vim.api.nvim_set_keymap("n", "m", "<Nop>", {
		noremap = true,
		silent = true,
	})

	vim.api.nvim_set_keymap("v", "m", "<Nop>", {
		noremap = true,
		silent = true,
	})

	-- Space as leader key
	vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", {
		noremap = true,
		silent = true,
	})

	-- Buffer management
	vim.keymap.set("n", "<leader>x", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent quit!")
	end, {
		noremap = true,
		silent = true,
		desc = "Buffer: Close",
	})

	vim.keymap.set("n", "<leader>s", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent write!")
	end, {
		noremap = true,
		silent = true,
		desc = "Buffer: Write",
	})

	vim.keymap.set("n", "<leader>w", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent write!")
		vim.cmd("silent quit!")
	end, {
		noremap = true,
		silent = true,
		desc = "Buffer: Write and close",
	})

	vim.keymap.set("n", "<leader>bn", "<cmd>bnext<CR>", {
		noremap = true,
		silent = true,
		desc = "Buffer: Next",
	})

	vim.keymap.set("n", "<leader>bp", "<cmd>bprev<CR>", {
		noremap = true,
		silent = true,
		desc = "Buffer: Previous",
	})

	vim.keymap.set("n", "<leader>q", ":qa!<CR>", {
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
		desc = "Editor: Toggle line number display",
	})
end

function M.register_autocmds()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "help",
		command = "wincmd L",
	})
end

function M.exec_fallback_entrypoint()
	if vim.fn.argc() > 0 and vim.fn.isdirectory(vim.fn.expand(vim.fn.argv()[1])) == 1 then
		vim.cmd("Alpha")
	end
end

return M
