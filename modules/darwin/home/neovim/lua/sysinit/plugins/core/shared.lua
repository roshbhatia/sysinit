local M = {}

M.plugins = {
	{
		"sysinit/core/shared",
		dir = vim.fn.stdpath("config") .. "/lua/sysinit/plugins/core",
		lazy = false,
		priority = 1000,
		config = function()
			-- Leader key setup
			vim.g.mapleader = " "
			vim.g.maplocalleader = " "

			-- Clipboard
			vim.o.clipboard = "unnamedplus"

			-- Editor behavior
			vim.opt.mouse = "a"
			vim.opt.number = true
			vim.opt.cursorline = false
			vim.opt.signcolumn = "yes"

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
			vim.opt.laststatus = 3
			vim.opt.shortmess:append("c")
			vim.opt.completeopt = { "menuone", "noselect" }

			-- Environment
			vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
			vim.o.autoread = true
		end,
		keys = function()
			return {
				-- Disable recording
				{ "q", "<Nop>", mode = "n" },

				-- Leader key setup
				{ "<Space>", "<Nop>", mode = { "n", "v" } },

				-- MacOS clipboard integration
				{ "<D-c>", '"+y', mode = "n", desc = "Copy to clipboard" },
				{ "<D-c>", '"+y', mode = "v", desc = "Copy to clipboard" },
				{ "<D-v>", '"+p', mode = "n", desc = "Paste from clipboard" },
				{ "<D-v>", '"+p', mode = "v", desc = "Paste from clipboard" },
				{ "<D-v>", "<C-r>+", mode = "i", desc = "Paste from clipboard" },
				{ "<D-v>", "<C-r>+", mode = "c", desc = "Paste from clipboard" },
				{ "<D-x>", '"+d', mode = "n", desc = "Cut to clipboard" },
				{ "<D-x>", '"+d', mode = "v", desc = "Cut to clipboard" },
				{ "<D-p>", '"+p', mode = "n", desc = "Paste from clipboard" },
				{ "<D-p>", '"+p', mode = "v", desc = "Paste from clipboard" },

				-- Buffer management
				{ "<leader>w", ":q!<CR>", mode = "n", desc = "Buffer: Close" },
				{ "<leader>q", ":w!<CR>", mode = "n", desc = "Buffer: Write" },
				{ "<leader>bn", "<cmd>bnext<CR>", mode = "n", desc = "Buffer: Next" },
				{ "<leader>bp", "<cmd>bprev<CR>", mode = "n", desc = "Buffer: Previous" },
				{ "<leader>Q", ":qa!<CR>", mode = "n", desc = "System: Close" },

				-- Toggle line numbers
				{
					"<leader>nn",
					function()
						if vim.wo.relativenumber then
							vim.wo.relativenumber = false
							vim.wo.number = true
						else
							vim.wo.relativenumber = true
							vim.wo.number = true
						end
					end,
					mode = "n",
					desc = "Editor: Toggle line numbers",
				},
			}
		end,
	},
}

return M
