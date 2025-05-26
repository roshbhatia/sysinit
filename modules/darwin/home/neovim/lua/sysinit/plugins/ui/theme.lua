local M = {}

M.plugins = {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1500,
		opts = {
			flavour = "macchiato",
			show_end_of_buffer = false,
			transparent_background = true,
			styles = { comments = { "italic" } },
			integrations = {
				alpha = true,
				aerial = true,
				cmp = true,
				gitsigns = true,
				nvimtree = true,
				treesitter = true,
				mason = true,
				neotree = true,
				noice = true,
				copilot_vim = true,
				dap = true,
				dap_ui = true,
				nvim_notify = false,
				render_markdown = true,
				snacks = { enabled = true },
				telescope = { enabled = true },
				lsp_trouble = true,
				which_key = true,
			},
		},
		config = function()
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}

return M

