local M = {}

M.plugins = {
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		version = false,
		build = ":AvanteBuild",
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
				},
				selector = {
					provider = "telescope",
				},
				disabled_tools = {
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
					"web_search",
				},
				system_prompt = function()
					local hub = require("mcphub").get_hub_instance()
					return hub:get_active_servers_prompt()
				end,
				custom_tools = function()
					return {
						require("mcphub.extensions.avante").mcp_tool(),
					}
				end,
			})

			vim.api.nvim_create_autocmd("BufWinEnter", {
				pattern = "*",
				callback = function()
					local bufname = vim.api.nvim_buf_get_name(0)
					if bufname:match("Avante Sidebar") then
						vim.cmd([[highlight Normal guibg=#1e1e1e]])

						vim.api.nvim_buf_set_option(0, "foldcolumn", "0")
						vim.api.nvim_buf_set_option(0, "foldenable", false)

						local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
						for i, line in ipairs(lines) do
							lines[i] = string.rep(" ", 2) .. line
						end
						vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
					end
				end,
			})
		end,
	},
}

return M
