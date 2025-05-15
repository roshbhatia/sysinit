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
	return nil
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
		if theme then
			vim.cmd.colorscheme(theme)
		end
	end,
})

M.plugins = {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
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
	},
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = { transparent = true, styles = { floats = "transparent" } },
	},
	{ "Abstract-IDE/Abstract-cs", name = "abstract-cs", lazy = false, priority = 1000 },
	{ "Mofiqul/adwaita.nvim", lazy = false, priority = 1000 },
	{ "rockyzhang24/arctic.nvim", lazy = false, priority = 1000 },
	{ "adisen99/apprentice.nvim", lazy = false, priority = 1000 },
	{ "FrenzyExists/aquarium-vim", lazy = false, priority = 1000 },
	{ "jim-at-jibba/ariake-vim-colors", lazy = false, priority = 1000 },
	{ "ray-x/aurora", lazy = false, priority = 1000 },
	{ "kyazdani42/blue-moon", lazy = false, priority = 1000 },
	{ "rockerBOO/boo-colorscheme-nvim", lazy = false, priority = 1000 },
	{ "hoprr/calvera-dark.nvim", lazy = false, priority = 1000 },
	{ "adisen99/codeschool.nvim", lazy = false, priority = 1000 },
	{ "NTBBloodBath/doom-one.nvim", lazy = false, priority = 1000 },
	{ "Mofiqul/dracula.nvim", lazy = false, priority = 1000 },
	{ "sainnhe/edge", lazy = false, priority = 1000 },
	{ "neanias/everforest-nvim", lazy = false, priority = 1000 },
	{ "fenetikm/falcon", lazy = false, priority = 1000 },
	{ "maxmx03/fluoromachine.nvim", lazy = false, priority = 1000 },
	{ "lourenci/github-colors", lazy = false, priority = 1000 },
	{ "projekt0n/github-nvim-theme", lazy = false, priority = 1000 },
	{ "bkegley/gloombuddy", lazy = false, priority = 1000 },
	{ "luisiacc/gruvbox-baby", lazy = false, priority = 1000 },
	{ "sainnhe/gruvbox-material", lazy = false, priority = 1000 },
	{ "RishabhRD/gruvy", lazy = false, priority = 1000 },
	{ "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },
	{ "lmburns/kimbox", lazy = false, priority = 1000 },
	{ "marko-cerovac/material.nvim", lazy = false, priority = 1000 },
	{ "savq/melange-nvim", lazy = false, priority = 1000 },
	{ "ramojus/mellifluous.nvim", lazy = false, priority = 1000 },
	{ "kvrohit/mellow.nvim", lazy = false, priority = 1000 },
	{ "dasupradyumna/midnight.nvim", lazy = false, priority = 1000 },
	{ "Yazeed1s/minimal.nvim", lazy = false, priority = 1000 },
	{ "ishan9299/modus-theme-vim", lazy = false, priority = 1000 },
	{ "kdheepak/monochrome.nvim", lazy = false, priority = 1000 },
	{ "tanvirtin/monokai.nvim", lazy = false, priority = 1000 },
	{ "bluz71/vim-moonfly-colors", lazy = false, priority = 1000 },
	{ "shaunsingh/moonlight.nvim", lazy = false, priority = 1000 },
	{ "rafamadriz/neon", lazy = false, priority = 1000 },
	{ "svrana/neosolarized.nvim", lazy = false, priority = 1000 },
	{ "bluz71/vim-nightfly-colors", lazy = false, priority = 1000 },
	{ "EdenEast/nightfox.nvim", lazy = false, priority = 1000 },
	{ "shaunsingh/nord.nvim", lazy = false, priority = 1000 },
	{ "andersevenrud/nordic.nvim", lazy = false, priority = 1000 },
	{ "ChristianChiarulli/nvcode-color-schemes.vim", lazy = false, priority = 1000 },
	{ "RRethy/nvim-base16", lazy = false, priority = 1000 },
	{ "theniceboy/nvim-deus", lazy = false, priority = 1000 },
	{ "PHSix/nvim-hybrid", lazy = false, priority = 1000 },
	{ "kaiuri/nvim-juliana", lazy = false, priority = 1000 },
	{ "mhartington/oceanic-next", lazy = false, priority = 1000 },
	{ "ofirgall/ofirkai.nvim", lazy = false, priority = 1000 },
	{ "Yazeed1s/oh-lucy.nvim", lazy = false, priority = 1000 },
	{ "yonlu/omni.vim", lazy = false, priority = 1000 },
	{ "Th3Whit3Wolf/onebuddy", lazy = false, priority = 1000 },
	{ "navarasu/onedark.nvim", lazy = false, priority = 1000 },
	{ "olimorris/onedarkpro.nvim", lazy = false, priority = 1000 },
	{ "rmehri01/onenord.nvim", lazy = false, priority = 1000 },
	{ "cpea2506/one_monokai.nvim", lazy = false, priority = 1000 },
	{ "Th3Whit3Wolf/one-nvim", lazy = false, priority = 1000 },
	{ "nyoom-engineering/oxocarbon.nvim", lazy = false, priority = 1000 },
	{ "chrsm/paramount-ng.nvim", lazy = false, priority = 1000 },
	{ "olivercederborg/poimandres.nvim", lazy = false, priority = 1000 },
	{ "kvrohit/rasmus.nvim", lazy = false, priority = 1000 },
	{
		"rose-pine/neovim",
		lazy = false,
		priority = 1000,
		opts = {
			dim_inactive_windows = true,
			styles = {
				transparency = true,
			},
		},
	},
	{ "lewpoly/sherbet.nvim", lazy = false, priority = 1000 },
	{ "ishan9299/nvim-solarized-lua", lazy = false, priority = 1000 },
	{ "sainnhe/sonokai", lazy = false, priority = 1000 },
	{ "Th3Whit3Wolf/space-nvim", lazy = false, priority = 1000 },
	{ "ray-x/starry.nvim", lazy = false, priority = 1000 },
	{ "kvrohit/substrata.nvim", lazy = false, priority = 1000 },
	{ "tiagovla/tokyodark.nvim", lazy = false, priority = 1000 },
	{ "tomasiser/vim-code-dark", lazy = false, priority = 1000 },
	{ "nxvu699134/vn-night.nvim", lazy = false, priority = 1000 },
	{ "Mofiqul/vscode.nvim", lazy = false, priority = 1000 },
	{ "mcchrish/zenbones.nvim", lazy = false, priority = 1000 },
	{ "phha/zenburn.nvim", lazy = false, priority = 1000 },
	{ "nvimdev/zephyr-nvim", lazy = false, priority = 1000 },
	{ "titanzero/zephyrium", lazy = false, priority = 1000 },
	{
		"zaldih/themery.nvim",
		command = { "Themery" },
		config = function()
			local available_colorschemes = vim.fn.getcompletion("", "color")
			local colorschemes = {}
			for _, colorscheme in ipairs(available_colorschemes) do
				table.insert(colorschemes, colorscheme)
			end

			require("themery").setup({
				themes = colorschemes,
			})
		end,
	},
}

return M
