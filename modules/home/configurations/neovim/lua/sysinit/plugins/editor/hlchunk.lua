local M = {}

local function get_palette_colors()
	local good = vim.api.nvim_get_hl(0, { name = "@variable", link = false })
	local error = vim.api.nvim_get_hl(0, { name = "Error", link = false })
	return {
		good = good and good.fg and string.format("#%06x", good.fg) or "#806d9c",
		error = error and error.fg and string.format("#%06x", error.fg) or "#c21f30",
	}
end

M.plugins = {
	{
		"shellRaining/hlchunk.nvim",
		event = {
			"BufReadPost",
		},
		config = function()
			local colors = get_palette_colors()
			require("hlchunk").setup({
				chunk = {
					enable = true,
					use_treesitter = true,
					duration = 100,
					delay = 100,
					style = {
						{ fg = colors.good },
						{ fg = colors.error },
					},
				},
				indent = {
					enable = false,
				},
				blank = {
					enable = false,
				},
				line_num = {
					enable = false,
				},
			})
		end,
	},
}

return M

