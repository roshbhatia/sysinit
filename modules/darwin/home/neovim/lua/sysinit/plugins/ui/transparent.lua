local M = {}

M.plugins = {
	{
		"xiyaowong/transparent.nvim",
		lazy = false,
		configure = function()
			require("transparent").setup({
				enable = true,
				extra_groups = {
					"NormalFloat",
					"NormalNC",
					"Normal",
					"SignColumn",
					"EndOfBuffer",
					"Folded",
					"FoldColumn",
					"LineNr",
					"CursorLineNr",
					"StatusLineNC",
				},
				exclude = {
					filetypes = { "help", "lazy", "mason", "TelescopePrompt", "TelescopeResults" },
					buftypes = { "terminal" },
				},
			})

			vim.api.nvim_create_autocmd("VimEnter", {
				pattern = "*",
				callback = function()
					vim.cmd("TransparentEnable")
				end,
			})
		end,
	},
}

return M
