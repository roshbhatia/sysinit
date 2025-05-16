-- sysinit.nvim.doc-url="https://github.com/stevearc/aerial.nvim"
local M = {}

M.plugins = {
	{
		"stevearc/aerial.nvim",
		commit = "2e00d1d4248f08dddfceacb8d2996e51e13e00f6",
		cmd = { "AerialToggle" },
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		config = function()
			require("aerial").setup({
				backends = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
				-- optionally use on_attach to set keymaps when aerial has attached to a buffer
				on_attach = function(bufnr)
					-- Jump forwards/backwards with '{' and '}'
					vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", {
						buffer = bufnr,
					})
					vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", {
						buffer = bufnr,
					})
				end,
			})
		end,
		keys = {
			{
				"<leader>oo",
				"<cmd>AerialToggle!<CR>",
				desc = "Outline: Toggle",
			},
		},
	},
}

return M
