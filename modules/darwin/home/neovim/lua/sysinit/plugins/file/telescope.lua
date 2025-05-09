local M = {}

M.plugins = {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"nvim-telescope/telescope-fzy-native.nvim",
			"nvim-telescope/telescope-dap.nvim",
			"nvim-telescope/telescope-live-grep-args.nvim",
		},
		config = function()
			local telescope = require("telescope")

			telescope.setup({
				defaults = {
					prompt_prefix = "   ",
					selection_caret = " ",
					entry_prefix = " ",
					sorting_strategy = "ascending",
					layout_config = {
						horizontal = {
							prompt_position = "top",
							preview_width = 0.55,
						},
						width = 0.87,
						height = 0.80,
					},
					mappings = {
						n = { ["q"] = require("telescope.actions").close },
					},
				},
				extensions = {
					fzy_native = {
						override_generic_sorter = true,
						override_file_sorter = true,
					},
					dap = {},
					live_grep_args = {},
					cmdline = {},
				},
				file_ignore_patterns = { ".git/", "node_modules", "poetry.lock", "vendor" },
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--hidden",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--trim",
				},
			})

			telescope.load_extension("fzy_native")
			telescope.load_extension("dap")
			telescope.load_extension("live_grep_args")
		end,
		keys = function()
			return {
				{
					"<leader>ff",
					"<cmd>Telescope find_files<cr>",
					desc = "Picker: Find files",
				},
				{
					"<leader>fg",
					"<cmd>Telescope live_grep<cr>",
					desc = "Picker: Live grep",
				},
				{
					"<leader>fb",
					"<cmd>Telescope buffers<cr>",
					desc = "Picker: Find buffers",
				},
				{
					"<leader>fh",
					"<cmd>Telescope help_tags<cr>",
					desc = "Picker: Help tags",
				},
			}
		end,
	},
}

return M
