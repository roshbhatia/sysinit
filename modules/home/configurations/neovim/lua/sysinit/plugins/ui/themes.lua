local M = {}

M.plugins = {
	{
		{
			"catppuccin/nvim",
			name = "catppuccin",
			config = function()
				require("catppuccin").setup({
					flavour = "frappe",
					show_end_of_buffer = false,
					transparent_background = true,
					term_colors = true,
					styles = {
						comments = {
							"italic",
						},
						conditionals = {
							"italic",
						},
						loops = {},
						functions = {},
						keywords = {
							"italic",
						},
						strings = {},
						variables = {},
						numbers = {},
						booleans = {},
						properties = {},
						types = {},
						operators = {},
					},
					integrations = {
						aerial = true,
						alpha = true,
						cmp = true,
						copilot_vim = true,
						dap = true,
						dap_ui = true,
						dropbar = {
							enabled = true,
						},
						fzf = true,
						gitsigns = true,
						grug_far = true,
						hop = true,
						lsp_trouble = true,
						mason = true,
						native_lsp = {
							enabled = true,
						},
						neotree = true,
						noice = true,
						render_markdown = true,
						snacks = {
							enabled = true,
						},
						telescope = {
							enabled = true,
						},
						treesitter = true,
						treesitter_context = true,
						which_key = true,
						window_picker = true,
					},
				})
				vim.cmd("colorscheme catppuccin")
			end,
		},
		{
			"EdenEast/nightfox.nvim",
			config = function()
				require("nightfox").setup({
					transparent = true,
					terminal_colors = true,
					dim_inactive = true,
				})
			end,
		},
		{
			"folke/tokyonight.nvim",
			config = function()
				require("tokyonight").setup({
					style = "moon",
					transparent = true,
					terminal_colors = true,
					styles = {
						comments = { italic = true },
						keywords = { italic = true },
						functions = {},
						variables = {},
						sidebars = "transparent",
						floats = "transparent",
					},
					dim_inactive = false,
					cache = true,
				})
			end,
		},
		{
			"rebelot/kanagawa.nvim",
			config = function()
				require("kanagawa").setup({
					compile = false,
					undercurl = true,
					commentStyle = { italic = true },
					functionStyle = {},
					keywordStyle = { italic = true },
					statementStyle = { bold = true },
					typeStyle = {},
					transparent = true,
					dimInactive = false,
					terminalColors = true,
					theme = "wave",
					background = {
						dark = "wave",
						light = "lotus",
					},
				})
			end,
		},
		{
			"navarasu/onedark.nvim",
			config = function()
				require("onedark").setup({
					style = "deep",
					transparent = true,
					term_colors = true,
					ending_tildes = false,
					cmp_itemkind_reverse = false,
					code_style = {
						comments = "italic",
						keywords = "none",
						functions = "none",
						strings = "none",
						variables = "none",
					},
					lualine = { transparent = true },
					diagnostics = {
						darker = true,
						undercurl = true,
						background = false,
					},
				})
			end,
		},
		{
			"marko-cerovac/material.nvim",
			config = function()
				require("material").setup({
					contrast = {
						terminal = false,
						sidebars = false,
						floating_windows = false,
						cursor_line = false,
						lsp_virtual_text = false,
						non_current_windows = false,
					},
					styles = {
						comments = { italic = true },
						strings = {},
						keywords = { italic = true },
						functions = {},
						variables = {},
						operators = {},
						types = {},
					},
					disable = {
						colored_cursor = false,
						borders = false,
						background = true,
						term_colors = false,
						eob_lines = true,
					},
					high_visibility = {
						lighter = false,
						darker = false,
					},
					lualine_style = "stealth",
					async_loading = true,
				})
			end,
		},
		{
			"sainnhe/edge",
			config = function()
				vim.g.edge_style = "neon"
				vim.g.edge_dim_foreground = 0
				vim.g.edge_disable_italic_comment = 0
				vim.g.edge_enable_italic = 1
				vim.g.edge_cursor = "auto"
				vim.g.edge_transparent_background = 2
				vim.g.edge_dim_inactive_windows = 0
				vim.g.edge_menu_selection_background = "blue"
				vim.g.edge_spell_foreground = "none"
				vim.g.edge_show_eob = 0
				vim.g.edge_float_style = "dim"
				vim.g.edge_diagnostic_text_highlight = 0
				vim.g.edge_diagnostic_line_highlight = 0
				vim.g.edge_diagnostic_virtual_text = "grey"
				vim.g.edge_current_word = "bold"
				vim.g.edge_inlay_hints_background = "none"
				vim.g.edge_disable_terminal_colors = 0
				vim.g.edge_lightline_disable_bold = 0
				vim.g.edge_better_performance = 1
			end,
		},
		{
			"sainnhe/gruvbox-material",
			config = function()
				vim.g.gruvbox_material_style = "hard"
				vim.g.gruvbox_material_background = "hard"
				vim.g.gruvbox_material_foreground = "material"
				vim.g.gruvbox_material_disable_italic_comment = 0
				vim.g.gruvbox_material_enable_italic = 1
				vim.g.gruvbox_material_cursor = "auto"
				vim.g.gruvbox_material_transparent_background = 2
				vim.g.gruvbox_material_dim_inactive_windows = 0
				vim.g.gruvbox_material_menu_selection_background = "blue"
				vim.g.gruvbox_material_spell_foreground = "none"
				vim.g.gruvbox_material_show_eob = 0
				vim.g.gruvbox_material_float_style = "dim"
				vim.g.gruvbox_material_diagnostic_text_highlight = 0
				vim.g.gruvbox_material_diagnostic_line_highlight = 0
				vim.g.gruvbox_material_diagnostic_virtual_text = "grey"
				vim.g.gruvbox_material_current_word = "bold"
				vim.g.gruvbox_material_inlay_hints_background = "none"
				vim.g.gruvbox_material_disable_terminal_colors = 0
				vim.g.gruvbox_material_lightline_disable_bold = 0
				vim.g.gruvbox_material_better_performance = 1
			end,
		},
		"rktjmp/lush.nvim",
		"sontungexpt/witch",
		"Abstract-IDE/Abstract-cs",
		"tomasiser/vim-code-dark",
		"Mofiqul/vscode.nvim",
		"marko-cerovac/material.nvim",
		"bluz71/vim-nightfly-colors",
		"bluz71/vim-moonfly-colors",
		"ChristianChiarulli/nvcode-color-schemes.vim",
		"folke/tokyonight.nvim",
		"comfysage/evergarden",
		"sainnhe/sonokai",
		"nyoom-engineering/oxocarbon.nvim",
		"kyazdani42/blue-moon",
		"mhartington/oceanic-next",
		"nvimdev/zephyr-nvim",
		"rockerBOO/boo-colorscheme-nvim",
		"jim-at-jibba/ariake.nvim",
		"ishan9299/modus-theme-vim",
		"sainnhe/edge",
		"theniceboy/nvim-deus",
		"PHSix/nvim-hybrid",
		"Th3Whit3Wolf/space-nvim",
		"yonlu/omni.vim",
		"ray-x/aurora",
		"tanvirtin/monokai.nvim",
		"ofirgall/ofirkai.nvim",
		"savq/melange-nvim",
		"fenetikm/falcon",
		"andersevenrud/nordic.nvim",
		"AlexvZyl/nordic.nvim",
		"shaunsingh/nord.nvim",
		"ishan9299/nvim-solarized-lua",
		"jthvai/lavender.nvim",
		"navarasu/onedark.nvim",
		"sainnhe/everforest",
		"neanias/everforest-nvim",
		"NTBBloodbath/doom-one.nvim",
		"dracula/vim",
		"Mofiqul/dracula.nvim",
		"niyabits/calvera-dark.nvim",
		"nxvu699134/vn-night.nvim",
		"adisen99/codeschool.nvim",
		"projekt0n/github-nvim-theme",
		"kdheepak/monochrome.nvim",
		"rose-pine/neovim",
		"zenbones-theme/zenbones.nvim",
		"FrenzyExists/aquarium-vim",
		"kvrohit/substrata.nvim",
		"ldelossa/vimdark",
		"Everblush/nvim",
		"adisen99/apprentice.nvim",
		"olimorris/onedarkpro.nvim",
		"rmehri01/onenord.nvim",
		"RishabhRD/gruvy",
		"luisiacc/gruvbox-baby",
		"titanzero/zephyrium",
		"rebelot/kanagawa.nvim",
		"sho-87/kanagawa-paper.nvim",
		"kevinm6/kurayami.nvim",
		"tiagovla/tokyodark.nvim",
		"cpea2506/one_monokai.nvim",
		"phha/zenburn.nvim",
		"kvrohit/rasmus.nvim",
		"chrsm/paramount-ng.nvim",
		"qaptoR-nvim/chocolatier.nvim",
		"rockyzhang24/arctic.nvim",
		"ramojus/mellifluous.nvim",
		"Yazeed1s/minimal.nvim",
		"Mofiqul/adwaita.nvim",
		"olivercederborg/poimandres.nvim",
		"mellow-theme/mellow.nvim",
		"gbprod/nord.nvim",
		"Yazeed1s/oh-lucy.nvim",
		"embark-theme/vim",
		"nyngwang/nvimgelion",
		"maxmx03/fluoromachine.nvim",
		"dasupradyumna/midnight.nvim",
		"uncleTen276/dark_flat.nvim",
		"zootedb0t/citruszest.nvim",
		"xero/miasma.nvim",
		"Verf/deepwhite.nvim",
		"judaew/ronny.nvim",
		"ribru17/bamboo.nvim",
		"cryptomilk/nightcity.nvim",
		"polirritmico/monokai-nightasty.nvim",
		"oxfist/night-owl.nvim",
		"miikanissi/modus-themes.nvim",
		"alexmozaidze/palenight.nvim",
		"scottmckendry/cyberdream.nvim",
		"HoNamDuong/hybrid.nvim",
		"bartekjaszczak/distinct-nvim",
		"samharju/synthweave.nvim",
		"ptdewey/darkearth-nvim",
		"uloco/bluloco.nvim",
		"slugbyte/lackluster.nvim",
		"0xstepit/flow.nvim",
		"samharju/serene.nvim",
		"killitar/obscure.nvim",
		"bakageddy/alduin.nvim",
		"diegoulloao/neofusion.nvim",
		"bartekjaszczak/luma-nvim",
		"bartekjaszczak/finale-nvim",
		"ellisonleao/gruvbox.nvim",
		"metalelf0/jellybeans-nvim",
		"lalitmee/cobalt2.nvim",
		"calind/selenized.nvim",
	},
}

return M
