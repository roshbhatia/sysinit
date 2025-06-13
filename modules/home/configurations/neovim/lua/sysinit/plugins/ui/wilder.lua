local M = {}

M.plugins = {
	{
		"gelguy/wilder.nvim",
		lazy = false,
		priority = 1000,
		dependencies = {
			"romgrk/fzy-lua-native",
			"kyazdani42/nvim-web-devicons",
		},
		build = ":UpdateRemotePlugins",
		config = function()
			local wilder = require("wilder")
			wilder.setup({
				modes = { ":", "/", "?" },
				next_key = "<Tab>",
				previous_key = "<S-Tab>",
				accept_key = "<CR>",
				reject_key = "<Esc>",
			})

			wilder.set_option("use_python_remote_plugin", 0)

			wilder.set_option("pipeline", {
				wilder.branch(
					{
						wilder.check(function(_, x)
							return vim.fn.empty(x)
						end),
						wilder.history(15),
					},
					wilder.cmdline_pipeline({
						fuzzy = 2,
						fuzzy_filter = wilder.lua_fzy_filter(),
					}),
					wilder.vim_search_pipeline()
				),
			})

			wilder.set_option(
				"renderer",
				wilder.popupmenu_renderer(wilder.popupmenu_palette_theme({
					border = "rounded",
					highlighter = wilder.lua_fzy_highlighter(),
				}))
			)
			vim.opt.wildignorecase = true
		end,
	},
}
return M

