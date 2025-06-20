local M = {}

M.plugins = {
	{
		enabled = true,
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
			"hrsh7th/nvim-cmp",
			"nvim-tree/nvim-web-devicons",
			"zbirenbaum/copilot.lua",
			"MeanderingProgrammer/render-markdown.nvim",
			"ravitemer/mcphub.nvim",
		},
		config = function()
			local avante = require("avante")

			avante.setup({
				provider = "copilot",
				mode = "legacy",
				auto_suggestions_provider = "copilot",
				behaviour = {
					auto_approve_tool_permissions = true,
					auto_focus_on_diff_view = true,
					auto_focus_sidebar = false,
					auto_suggestions = false,
					auto_apply_diff_after_generation = true,
					support_paste_from_clipboard = true,
				},
				mappings = {
					submit = {
						normal = "<CR>",
						insert = "<S-CR>",
					},
					ask = "<leader>at",
					toggle = {
						default = "<leader>aa",
					},
				},
				selector = {
					provider = "telescope",
				},
				disabled_tools = {
					"web_search",
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

			vim.api.nvim_create_autocmd({ "BufDelete" }, {
				group = augroup,
				callback = function(args)
					local bufname = vim.api.nvim_buf_get_name(args.buf)

					if bufname ~= "" then
						pcall(function()
							require("avante.selected_files").remove_file(bufname)
						end)
					end
				end,
			})
		end,
	},
}
return M
