return {
	{
		label = "Open File",
		key = "o",
		action = function()
			vim.cmd("Neotree open")
		end,
	},
	{
		label = "Split Right",
		key = "v",
		action = function()
			vim.cmd("Neotree action=split")
		end,
	},
	{
		label = "Split Below",
		key = "s",
		action = function()
			vim.cmd("Neotree action=vsplit")
		end,
	},
	{
		label = "Add File",
		key = "a",
		action = function()
			vim.cmd("Neotree add")
		end,
	},
	{
		label = "Delete File",
		key = "d",
		action = function()
			vim.cmd("Neotree delete")
		end,
	},
	{
		label = "Rename File",
		key = "r",
		action = function()
			vim.cmd("Neotree rename")
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

