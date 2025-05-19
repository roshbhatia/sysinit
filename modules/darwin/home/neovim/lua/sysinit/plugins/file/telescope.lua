local M = {}

M.plugins = {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"nvim-telescope/telescope-fzy-native.nvim",
			"nvim-telescope/telescope-dap.nvim",
			"nvim-telescope/telescope-live-grep-args.nvim",
			"debugloop/telescope-undo.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				defaults = {
					prompt_prefix = "   ",
					selection_caret = " > ",
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
						n = {
							["q"] = actions.close,
							["<Tab>"] = actions.move_selection_next,
							["<S-Tab>"] = actions.move_selection_previous,
						},
						i = {
							["<Tab>"] = actions.move_selection_next,
							["<S-Tab>"] = actions.move_selection_previous,
						},
					},
				},
				extensions = {
					fzy_native = {
						override_generic_sorter = true,
						override_file_sorter = true,
					},
					dap = {},
					live_grep_args = {},
					undo = {
						side_by_side = true,
						layout_strategy = "vertical",
						layout_config = {
							preview_height = 0.8,
						},
					},
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
			telescope.load_extension("undo")
		end,
		keys = function()
			return {
				{
					"<leader>ff",
					"<cmd>Telescope find_files hidden=true<cr>",
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
					desc = "Picker: Find buffers sort_mru=true ignore_current_buffer=true show_all_buffers=false",
				},
				{
					"<leader>fc",
					"<cmd>Telescope commands<cr>",
					desc = "Picker: Find commands",
				},
				{
					"<leader>fh",
					"<cmd>Telescope help_tags<cr>",
					desc = "Picker: Find help tags",
				},
				{
					"<leader>fr",
					"<cmd>Telescope oldfiles<cr>",
					desc = "Picker: Find recent files",
				},
				{
					"<leader>ft",
					"<cmd>Telescope filetypes<cr>",
					desc = "Picker: Find filetypes",
				},
				{
					"<leader>fF",
					"<cmd>Telescope<cr>",
					desc = "Picker: Telescope",
				},
				{
					"<leader>fu",
					"<cmd>Telescope undo<cr>",
					desc = "Picker: Undo history",
				},
				{
					"<leader>fm",
					"<cmd>Telescope marks<cr>",
					desc = "Picker: Marks",
				},
			}
		end,
	},
}

return M
