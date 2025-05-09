local M = {}

local function get_theme()
	local theme_file = vim.fn.stdpath("data") .. "/theme"
	local f = io.open(theme_file, "r")
	if f then
		local theme = f:read("*l")
		f:close()
		if theme and #theme > 0 then
			return theme
		end
	end
	return "catpuccin"
end

local function set_theme(theme)
	local theme_file = vim.fn.stdpath("data") .. "/theme"
	local f = io.open(theme_file, "w")
	if f then
		f:write(theme)
		f:close()
	end
end

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local theme = get_theme()
		vim.cmd.colorscheme(theme)
	end,
})

M.plugins = {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		opts = {
			flavour = "macchiato", -- latte, frappe, macchiato, mocha
			transparent_background = true, -- disables setting the background color.
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
				nvim_notify = true,
				render_markdown = true,
				snacks = {
					enabled = true,
				},
				telescope = {
					enabled = true,
				},
				lsp_trouble = true,
				which_key = true,
			},
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)
		end,
	},
	{ "folke/tokyonight.nvim", lazy = false, priority = 1000 },
	{ "AlexvZyl/nordic.nvim", lazy = false, priority = 1000 },
	{ "EdenEast/nightfox.nvim", lazy = false, priority = 1000 },
	{ "shaunsingh/nord.nvim", lazy = false, priority = 1000 },
	{ "marko-cerovac/material.nvim", lazy = false, priority = 1000 },
	{ "projekt0n/github-nvim-theme", lazy = false, priority = 1000 },
	{ "olimorris/onedarkpro.nvim", lazy = false, priority = 1000 },
	{ "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },
	{ "nyoom-engineering/oxocarbon.nvim", lazy = false, priority = 1000 },
	{ "sainnhe/everforest", lazy = false, priority = 1000 },
	{ "sainnhe/gruvbox-material", lazy = false, priority = 1000 },
	{ "sainnhe/sonokai", lazy = false, priority = 1000 },
	{ "Shatur/neovim-ayu", lazy = false, priority = 1000 },
	{ "Mofiqul/vscode.nvim", lazy = false, priority = 1000 },
	{ "tiagovla/tokyodark.nvim", lazy = false, priority = 1000 },
	{ "morhetz/gruvbox", lazy = false, priority = 1000 },
	{ "glepnir/zephyr-nvim", lazy = false, priority = 1000 },
	{ "rafamadriz/neon", lazy = false, priority = 1000 },
	{ "savq/melange-nvim", lazy = false, priority = 1000 },
	{ "Shatur/neovim-ayu", lazy = false, priority = 1000 },
	{ "rmehri01/onenord.nvim", lazy = false, priority = 1000 },
	{ "olivercederborg/poimandres.nvim", lazy = false, priority = 1000 },
	{ "maxmx03/fluoromachine.nvim", lazy = false, priority = 1000 },
	{ "kvrohit/substrata.nvim", lazy = false, priority = 1000 },
	{ "NTBBloodbath/sweetie.nvim", lazy = false, priority = 1000 },
	{
		"zaldih/themery.nvim",
		lazy = true,
		event = "VeryLazy",
		opts = {
			themes = {
				"catppuccin",
				"tokyonight-night",
				"tokyonight-storm",
				"tokyonight-moon",
				"nordic",
				"nightfox",
				"duskfox",
				"nordfox",
				"terafox",
				"carbonfox",
				"nord",
				"material-oceanic",
				"material-palenight",
				"github_dark",
				"github_dark_dimmed",
				"github_dark_default",
				"github_dark_high_contrast",
				"onedark",
				"kanagawa",
				"oxocarbon",
				"everforest",
				"gruvbox-material",
				"sonokai",
				"ayu",
				"vscode",
				"tokyodark",
				"gruvbox",
				"zephyr",
				"neon",
				"melange",
				"onenord",
				"poimandres",
				"fluoromachine",
				"substrata",
				"sweetie",
			},
			livePreview = true,
			onApply = function(theme)
				set_theme(theme)
			end,
		},
	},
}

return M
