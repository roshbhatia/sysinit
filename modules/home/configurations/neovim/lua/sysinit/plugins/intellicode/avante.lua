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
					ask = "<leader>as",
					toggle = {
						default = "<leader>aa",
					},
				},
				hints = {
					enabled = false,
				},
				selector = {
					provider = "telescope",
				},
				system_prompt = function()
					local hub = require("mcphub").get_hub_instance()
					return hub and hub:get_active_servers_prompt() or ""
				end,
				custom_tools = function()
					return {
						require("mcphub.extensions.avante").mcp_tool(),
					}
				end,
				disabled_tools = {
					-- Disabled due to conflicts with mcphub
					"list_files",
					"search_files",
					"read_file",
					"create_file",
					"rename_file",
					"delete_file",
					"create_dir",
					"rename_dir",
					"delete_dir",
					"bash",
					-- Disabled due to lack of use in favor with fetch
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
		end,
	},
}
return M
