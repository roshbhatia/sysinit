local M = {}
M.plugins = {
	{
		"jake-stewart/multicursor.nvim",
		branch = "1.0",
		config = function()
			local mc = require("multicursor-nvim")
			mc.setup()
			-- Mappings defined in a keymap layer only apply when there are
			-- multiple cursors. This lets you have overlapping mappings.
			mc.addKeymapLayer(function(layerSet)
				-- Select a different cursor as the main one.
				layerSet("n", "<left>", mc.prevCursor)
				layerSet("n", "<right>", mc.nextCursor)
				-- Delete the main cursor.
				layerSet("n", "<leader>kx", mc.deleteCursor)
				-- Enable and clear cursors using escape.
				layerSet("n", "<esc>", function()
					if not mc.cursorsEnabled() then
						mc.enableCursors()
					else
						mc.clearCursors()
					end
				end)
			end)
			-- Customize how cursors look.
			local hl = vim.api.nvim_set_hl
			hl(0, "MultiCursorCursor", { reverse = true })
			hl(0, "MultiCursorVisual", { link = "Visual" })
			hl(0, "MultiCursorSign", { link = "SignColumn" })
			hl(0, "MultiCursorMatchPreview", { link = "Search" })
			hl(0, "MultiCursorDisabledCursor", { reverse = true })
			hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
			hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
		end,
		keys = function()
			local mc = require("multicursor-nvim")
			return {
				-- Add or skip cursor above/below the main cursor.
				{
					"<leader>k<up>",
					function()
						mc.lineAddCursor(-1)
					end,
					mode = "n",
					desc = "Add cursor above",
				},
				{
					"<leader>k<down>",
					function()
						mc.lineAddCursor(1)
					end,
					mode = "n",
					desc = "Add cursor below",
				},
				{
					"<leader>k<leader><up>",
					function()
						mc.lineSkipCursor(-1)
					end,
					mode = "n",
					desc = "Skip cursor above",
				},
				{
					"<leader>k<leader><down>",
					function()
						mc.lineSkipCursor(1)
					end,
					mode = "n",
					desc = "Skip cursor below",
				},
				-- Add or skip adding a new cursor by matching word/selection
				{
					"<leader>kn",
					function()
						mc.matchAddCursor(1)
					end,
					mode = "n",
					desc = "Add cursor to next match",
				},
				{
					"<leader>ks",
					function()
						mc.matchSkipCursor(1)
					end,
					mode = "n",
					desc = "Skip next match",
				},
				{
					"<leader>kN",
					function()
						mc.matchAddCursor(-1)
					end,
					mode = "n",
					desc = "Add cursor to previous match",
				},
				{
					"<leader>kS",
					function()
						mc.matchSkipCursor(-1)
					end,
					mode = "n",
					desc = "Skip previous match",
				},
				{
					"<leader>kq",
					mc.toggleCursor,
					mode = "n",
					desc = "Toggle cursor",
				},
			}
		end,
	},
}
return M
