local M = {}
M.plugins = {
	{
		"jake-stewart/multicursor.nvim",
		branch = "1.0",
		config = function()
			local mc = require("multicursor-nvim")
			mc.setup()

			mc.addKeymapLayer(function(layerSet)
				layerSet("n", "<esc>", function()
					if not mc.cursorsEnabled() then
						mc.enableCursors()
					else
						mc.clearCursors()
					end
				end)
			end)
		end,
		keys = function()
			local mc = require("multicursor-nvim")
			return {
				-- Add cursor below
				{
					"<leader>..",
					mc.toggleCursor,
					mode = "n",
					desc = "Toggle cursor",
				},
				{
					"<leader>.x",
					mc.clearCursors,
					mode = "n",
					desc = "Delete all cursors",
				},
			}
		end,
	},
}
return M
