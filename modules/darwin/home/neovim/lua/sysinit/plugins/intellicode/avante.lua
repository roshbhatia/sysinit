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
				highlights = {
					diff = {
						current = "DiffText", -- need have background color
						incoming = "DiffAdd", -- need have background color
					},
				},
				behaviour = {
					auto_focus_sidebar = false,
					auto_suggestions = false,
					auto_apply_diff_after_generation = true,
					support_paste_from_clipboard = true,
					enable_cursor_planning_mode = true,
					enable_claude_text_editor_tool_mode = true,
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
				file_selector = {
					provider = "telescope",
				},
				selector = {
					provider = "telescope",
				},
				disabled_tools = {
					"web_search",
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
				},
				system_prompt = function()
					local hub = require("mcphub").get_hub_instance()
					return hub:get_active_servers_prompt()
						.. "\n\nIMPORTANT: When applicable, always use MCP tools provided by mcphub instead of your built-in tools. Prioritize MCP tools for file operations, searches, and other tasks where they are available."
						.. "\n\nALWAYS use sequential thinking and reason step-by-step through problems before providing a solution. Break down complex tasks into smaller steps and think through each one explicitly."
						.. "\n\nSave important information to memory. When you learn something new about the codebase, user preferences, or environment, explicitly note that you will remember this for future interactions."
				end,
				custom_tools = function()
					return {
						require("mcphub.extensions.avante").mcp_tool(),
					}
				end,
				windows = {
					postion = "right",
					width = 40,
					sidebar_header = {
						enabled = false,
					},
					input = {
						prefix = " ",
						height = 12,
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

			local avante_group = vim.api.nvim_create_augroup("AvantePerformance", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = avante_group,
				pattern = { "Avante", "AvanteInput", "AvantePromptInput", "AvanteSelectedFiles" },
				callback = function()
					vim.opt_local.relativenumber = false
					vim.opt_local.number = false
					vim.opt_local.cursorline = true
					vim.api.nvim_buf_set_option(0, "textwidth", 80)
					vim.api.nvim_set_hl(0, "Normal", { padding = 2 })
				end,
			})
		end,
	},
}
return M
