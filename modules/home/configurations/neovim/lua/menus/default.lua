return {
	{
		label = "Split Right",
		key = "<localleader>v",
		action = function()
			vim.cmd("vsplit")
		end,
	},
	{
		label = "Split Below",
		key = "<localleader>s",
		action = function()
			vim.cmd("split")
		end,
	},
	{
		label = "Buffers",
		key = "<leader>fb",
		action = function()
			vim.cmd("Telescope buffers")
		end,
	},
	{
		label = "Files",
		key = "<leader>ff",
		action = function()
			vim.cmd("Telescope find_files")
		end,
	},
	{
		label = "File Explorer",
		key = "<leader>et",
		action = function()
			vim.cmd("Neotree toggle")
		end,
	},
	{
		label = "LSP Actions",
		key = "<leader>ca",
		action = function()
			require("menu").open("lsp")
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

