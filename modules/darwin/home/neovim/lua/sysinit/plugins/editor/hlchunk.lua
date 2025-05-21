local M = {}

M.plugins = {
	{
		"shellRaining/hlchunk.nvim",
		commit = "474ec5d0f220158afa83aaefab32402e710d3032",
		event = { "VeryLazy" },
		config = function()
			require("hlchunk").setup({
				exclude_filetypes = {
					[""] = true, -- because TelescopePrompt will set a empty ft, so add this.
					aerial = true,
					alpha = true,
					better_term = true,
					checkhealth = true,
					cmp_menu = true,
					dashboard = true,
					["dap-repl"] = true,
					DiffviewFileHistory = true,
					DiffviewFiles = true,
					DressingInput = true,
					fugitiveblame = true,
					glowpreview = true,
					help = true,
					lazy = true,
					lspinfo = true,
					lspsagafinder = true,
					man = true,
					mason = true,
					Navbuddy = true,
					NeogitPopup = true,
					NeogitStatus = true,
					["neo-tree"] = false, -- explicitly reenable this
					["neo-tree-popup"] = true,
					noice = true,
					notify = true,
					NvimTree = true,
					oil = true,
					Outline = true,
					OverseerList = true,
					packer = true,
					plugin = true,
					qf = true,
					query = true,
					registers = true,
					saga_codeaction = true,
					sagaoutline = true,
					sagafinder = true,
					sagarename = true,
					spectre_panel = true,
					startify = true,
					startuptime = true,
					starter = true,
					TelescopePrompt = true,
					toggleterm = true,
					Trouble = true,
					trouble = true,
					zsh = true,
				},
				chunk = {
					enable = true,
				},
				indent = {
					enable = false,
				},
				blank = {
					enable = false,
				},
				line_num = {
					enablechunk = true,
					use_treesitter = true,
				},
			})
		end,
	},
}

return M

