local M = {}

local function get_bg_color()
	local hl = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
	return hl and hl.bg and string.format("#%06x", hl.bg) or "#949cbb"
end

M.plugins = {
	{
		"rachartier/tiny-glimmer.nvim",
		event = "VeryLazy",
		priority = 10,
		config = function()
			require("tiny-glimmer").setup({
				enabled = true,
				overwrite = {
					search = {
						enabled = true,
					},
					undo = {
						enabled = true,
						undo_mapping = "u",
					},
					redo = {
						enabled = true,
						redo_mapping = "U",
					},
				},
				transparency_color = get_bg_color(),
			})
		end,
	},
}

return M
