return {
	{
		label = "Code Action (fastaction)",
		key = "<leader>ca",
		action = function()
			require("fastaction").code_action()
		end,
	},
	{
		label = "Rename Symbol",
		key = "<leader>cr",
		action = function()
			vim.lsp.buf.rename()
		end,
	},
	{
		label = "Hover",
		key = "<leader>ch",
		action = function()
			require("pretty_hover").hover()
		end,
	},
	{
		label = "Go to Definition",
		key = "<leader>cD",
		action = function()
			vim.lsp.buf.definition()
		end,
	},
	{
		label = "Toggle Diagnostics",
		key = "<leader>cx",
		action = function()
			vim.cmd("TroubleToggle")
		end,
	},
	{
		label = "Close Menu",
		key = "q",
		action = function()
			require("menu").close()
		end,
	},
}

