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
	return "nordfox"
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
	{ "folke/tokyonight.nvim", lazy = true, event = "VeryLazy" },
	{ "AlexvZyl/nordic.nvim", lazy = true, event = "VeryLazy" },
	{ "EdenEast/nightfox.nvim", lazy = true, event = "VeryLazy" },
	{ "shaunsingh/nord.nvim", lazy = true, event = "VeryLazy" },
	{ "marko-cerovac/material.nvim", lazy = true, event = "VeryLazy" },
	{ "projekt0n/github-nvim-theme", lazy = true, event = "VeryLazy" },
	{ "olimorris/onedarkpro.nvim", lazy = true, event = "VeryLazy" },
	{ "rebelot/kanagawa.nvim", lazy = true, event = "VeryLazy" },
	{ "nyoom-engineering/oxocarbon.nvim", lazy = true, event = "VeryLazy" },
	{ "sainnhe/everforest", lazy = true, event = "VeryLazy" },
	{ "sainnhe/gruvbox-material", lazy = true, event = "VeryLazy" },
	{ "sainnhe/sonokai", lazy = true, event = "VeryLazy" },
	{ "Shatur/neovim-ayu", lazy = true, event = "VeryLazy" },
	{ "Mofiqul/vscode.nvim", lazy = true, event = "VeryLazy" },
	{ "tiagovla/tokyodark.nvim", lazy = true, event = "VeryLazy" },
	{ "morhetz/gruvbox", lazy = true, event = "VeryLazy" },
	{ "glepnir/zephyr-nvim", lazy = true, event = "VeryLazy" },
	{ "rafamadriz/neon", lazy = true, event = "VeryLazy" },
	{ "savq/melange-nvim", lazy = true, event = "VeryLazy" },
	{ "Shatur/neovim-ayu", lazy = true, event = "VeryLazy" },
	{ "rmehri01/onenord.nvim", lazy = true, event = "VeryLazy" },
	{ "olivercederborg/poimandres.nvim", lazy = true, event = "VeryLazy" },
	{ "maxmx03/fluoromachine.nvim", lazy = true, event = "VeryLazy" },
	{ "kvrohit/substrata.nvim", lazy = true, event = "VeryLazy" },
	{ "NTBBloodbath/sweetie.nvim", lazy = true, event = "VeryLazy" },
	{
		"zaldih/themery.nvim",
		lazy = true,
		event = "VeryLazy",
		opts = {
			themes = {
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
