local M = {}

M.plugins = {
	{
		"gelguy/wilder.nvim",
		lazy = false,
		priority = 1000,
		dependencies = {
			"romgrk/fzy-lua-native",
		},
		config = function()
			local wilder = require("wilder")
			wilder.setup({ modes = { ":", "/", "?" } })

			wilder.set_option("use_python_remote_plugin", 0)

			wilder.set_option("pipeline", {
				wilder.branch(
					wilder.cmdline_pipeline({
						fuzzy = 1,
						fuzzy_filter = wilder.lua_fzy_filter(),
					}),
					wilder.vim_search_pipeline()
				),
			})

			wilder.set_option(
				"renderer",
				wilder.popupmenu_renderer(wilder.popupmenu_palette_theme({
					highlighter = wilder.lua_fzy_highlighter(),
					left = { " ", wilder.popupmenu_devicons() },
					right = { " ", wilder.popupmenu_scrollbar() },
					max_height = "65%",
					min_height = "0",
					pumblend = 0,
					border = "rounded",
					prompt_position = "top",
					reverse = 0,
				}))
			)
		end,
	},
}
return M
