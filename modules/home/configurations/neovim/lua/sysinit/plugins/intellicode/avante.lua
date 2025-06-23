local M = {}

M.plugins = {
	{
		enabled = not vim.uv.fs_stat(vim.fn.expand("~/.nocopilot")),
		"yetone/avante.nvim",
		event = "VeryLazy",
		version = false,
		build = "make",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
			"zbirenbaum/copilot.lua",
			"MeanderingProgrammer/render-markdown.nvim",
		},
		config = function()
			local avante = require("avante")
			avante.setup({
				provider = "copilot",
				mode = "agentic",
				providers = {
					copilot = {
						model = "gpt-4.1",
					},
				},
				behaviour = {
					auto_suggestions = false,
				},
				prompt_logger = {
					next_prompt = {
						normal = "j",
						insert = "<Down>",
					},
					prev_prompt = {
						normal = "h",
						insert = "<Up>",
					},
				},
				mappings = {
					submit = {
						normal = "<CR>",
						insert = "<S-CR>",
					},
					ask = "<leader>as",
					new_ask = "<leader>aA",
					toggle = {
						default = "<leader>aa",
						suggestion = "<leader>a\\",
					},
					sidebar = {
						switch_windows = "<C-Tab>",
						reverse_switch_windows = "<C-S-Tab>",
					},
				},
				selector = {
					provider = "telescope",
				},
				disabled_tools = {
					-- Disabled due to lack of use in favor with fetch
					"web_search",
				},
				windows = {
					sidebar_header = {
						rounded = false,
					},
					input = {
						height = 24,
					},
					edit = {
						border = {
							"╭",
							"─",
							"╮",
							"│",
							"╯",
							"─",
							"╰",
							"│",
						},
					},
					ask = {
						border = {
							"╭",
							"─",
							"╮",
							"│",
							"╯",
							"─",
							"╰",
							"│",
						},
					},
				},
			})

			local augroup = vim.api.nvim_create_augroup("AvanteAutoBufferSelection", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter" }, {
				group = augroup,
				callback = function()
					local bufnr = vim.api.nvim_get_current_buf()
					local bufname = vim.api.nvim_buf_get_name(bufnr)

					if bufname ~= "" then
						pcall(function()
							require("avante.selected_files").add_file(bufname)
						end)
					end
				end,
			})

			vim.api.nvim_create_autocmd("FileType", {
				group = augroup,
				pattern = "Avante",
				callback = function()
					vim.opt_local.foldcolumn = "0"
					vim.opt_local.foldtext = ""
					vim.opt_local.foldmethod = "manual"
				end,
			})
		end,
	},
}

return M

