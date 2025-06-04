local M = {}

M.plugins = {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		event = "VeryLazy",
		dependencies = {
			"debugloop/telescope-undo.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-dap.nvim",
			"nvim-telescope/telescope-fzy-native.nvim",
			"nvim-telescope/telescope-live-grep-args.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
			"nvim-tree/nvim-web-devicons",
			"olimorris/persisted.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			local themes = require("telescope.themes")

			telescope.setup({
				defaults = {
					prompt_prefix = "   ",
					selection_caret = "",
					entry_prefix = "",
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
					["ui-select"] = {
						themes.get_dropdown(),
					},
					persisted = {
						layout_config = { width = 0.55, height = 0.55 },
					},
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
				file_ignore_patterns = {
					-- Git
					"^%.git/",
					"%.git/.*",
					-- Dependencies
					"^node_modules/",
					"node_modules/.*",
					"^vendor/",
					"vendor/.*",
					"poetry%.lock",
					"package%-lock%.json",
					"yarn%.lock",
					"Cargo%.lock",
					-- Cache/Build
					"^%.cache/",
					"%.cache/.*",
					"^build/",
					"^dist/",
					"^target/",
					"%.o$",
					"%.a$",
					"%.out$",
					"%.class$",
					"%.pyc$",
					"__pycache__/.*",
					-- Media files
					"%.pdf$",
					"%.mkv$",
					"%.mp4$",
					"%.avi$",
					"%.mov$",
					"%.zip$",
					"%.tar%.gz$",
					"%.rar$",
					"%.7z$",
					"%.jpeg$",
					"%.jpg$",
					"%.png$",
					"%.gif$",
					"%.webp$",
					"%.heic$",
					"%.svg$",
					-- Project specific
					"^%.goose/",
					"%.goose/.*",
				},
				pickers = {
					find_files = {
						find_command = {
							"fd",
							"--type",
							"f",
							"--hidden",
							"--exclude",
							".git",
							"--exclude",
							"node_modules",
							"--exclude",
							"vendor",
							"--exclude",
							".cache",
							"--exclude",
							"build",
							"--exclude",
							"dist",
							"--exclude",
							"target",
							"--exclude",
							".goose",
						},
					},
				},
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

			telescope.load_extension("ui-select")
			telescope.load_extension("persisted")
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
					desc = "Find: Files",
				},
				{
					"<leader>fg",
					"<cmd>Telescope live_grep<cr>",
					desc = "Find: Live grep",
				},
				{
					"<leader>fb",
					"<cmd>Telescope buffers sort_mru=true ignore_current_buffer=true show_all_buffers=false<cr>",
					desc = "Find: Buffers",
				},
				{
					"<leader>fc",
					"<cmd>Telescope commands<cr>",
					desc = "Find: Commands",
				},
				{
					"<leader>fh",
					"<cmd>Telescope help_tags<cr>",
					desc = "Find: Help tags",
				},
				{
					"<leader>fo",
					"<cmd>Telescope oldfiles<cr>",
					desc = "Find: Recent files",
				},
				{
					"<leader>ft",
					"<cmd>Telescope filetypes<cr>",
					desc = "Find: Filetypes",
				},
				{
					"<leader>fF",
					"<cmd>Telescope<cr>",
					desc = "Find: Telescope",
				},
				{
					"<leader>fu",
					"<cmd>Telescope undo<cr>",
					desc = "Find: Undo history",
				},
			}
		end,
	},
}

return M

