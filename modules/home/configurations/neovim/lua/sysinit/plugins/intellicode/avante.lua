local nvim_config = require("sysinit.config.nvim_config").load_config()
local M = {}

M.plugins = {
	{
		enabled = nvim_config.copilot.enabled,
		"yetone/avante.nvim",
		event = "VeryLazy",
		version = false,
		build = function()
			return "make BUILD_FROM_SOURCE=true"
		end,
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
				provider = nvim_config.avante.provider,
				mode = "agentic",
				providers = nvim_config.avante.providers,
				behaviour = {
					auto_suggestions = true,
				},
				prompt_logger = {
					next_prompt = {
						normal = "<Down>",
						insert = "<Down>",
					},
					prev_prompt = {
						normal = "<Up>",
						insert = "<Up>",
					},
				},
				mappings = {
					submit = {
						normal = "<S-CR>",
						insert = "<CR>",
					},
					ask = "<leader>hh",
					new_ask = "<leader>hH",
					edit = "<leader>he",
					refresh = "<leader>hr",
					focus = "<leader>hf",
					stop = "<leader>hS",
					toggle = {
						default = "<leader>ht",
						debug = "<leader>hd",
						hint = "<leader>hi",
						suggestion = "<leader>hs",
						repomap = "<leader>hR",
					},
					sidebar = {
						switch_windows = "<localleader>[",
						reverse_switch_windows = "<localleader>]",
					},
					files = {
						add_current = "<leader>hc",
						add_all_buffers = "<leader>hB",
					},
					select_model = "<leader>h?",
					select_history = "<leader>hy",
				},
				selector = {
					provider = "telescope",
				},
				input = {
					provider = "snacks",
					provider_opts = {},
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
						height = 20,
					},
					edit = {
						border = "rounded",
					},
					ask = {
						floating = true,
						border = "rounded",
					},
					spinner = {
						editing = {
							"-",
							"|",
							"-",
							"|",
							"-",
							"|",
							"-",
							"|",
							"-",
							"|",
						},
						generating = {
							"-",
							"|",
							"-",
							"|",
							"-",
							"|",
							"-",
							"|",
							"-",
							"|",
						},
						thinking = {
							"-",
							"|",
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

