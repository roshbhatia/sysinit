local M = {}

M.plugins = {
	{
		"MagicDuck/grug-far.nvim",
		config = function()
			require("grug-far").setup({
				normalMOdeSearch = true,
				keymaps = {
					replace = { n = "<localleader>gr" },
					qflist = { n = "<localleader>gq" },
					syncLocations = { n = "<localleader>gs" },
					syncLine = { n = "<localleader>gl" },
					close = { n = "<localleader>gc" },
					historyOpen = { n = "<localleader>gt" },
					historyAdd = { n = "<localleader>ga" },
					refresh = { n = "<localleader>gf" },
					openLocation = { n = "<localleader>go" },
					openNextLocation = { n = "<down>" },
					openPrevLocation = { n = "<up>" },
					gotoLocation = { n = "<enter>" },
					pickHistoryEntry = { n = "<enter>" },
					abort = { n = "<localleader>gb" },
					help = { n = "g?" },
					toggleShowCommand = { n = "<localleader>gw" },
					swapEngine = { n = "<localleader>ge" },
					previewLocation = { n = "<localleader>gi" },
					swapReplacementInterpreter = { n = "<localleader>gx" },
					applyNext = { n = "<localleader>gj" },
					applyPrev = { n = "<localleader>gk" },
					syncNext = { n = "<localleader>gn" },
					syncPrev = { n = "<localleader>gp" },
					syncFile = { n = "<localleader>gv" },
					nextInput = { n = "<tab>" },
					prevInput = { n = "<s-tab>" },
				},
			})
		end,
		event = "VeryLazy",
		keys = function()
			return {
				{
					"<leader>iI",
					function()
						require("grug-far").toggle_instance({ instanceName = "far", staticTitle = "Global Search" })
					end,
					desc = "Search and replace within current project",
				},
			}
		end,
	},
}

return M

