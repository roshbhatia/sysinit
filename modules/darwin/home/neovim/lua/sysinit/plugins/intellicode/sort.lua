local M = {}

M.plugins = {
	{
		"sQVe/sort.nvim",
		event = "VeryLazy",
		keys = function()
			return {
				{
					"<leader>ss",
					"<Cmd>Sort il<CR>",
					mode = "v",
					desc = "Sort: Sort selection alphabetically",
				},
			}
		end,
		config = function()
			require("sort").setup()

			local function format_json(start_line, end_line)
				local cmd = "'<,'>!jq --sort-keys ."
				if start_line == 1 and end_line == vim.fn.line("$") then
					cmd = "%!jq --sort-keys ."
				end
				vim.cmd(cmd)
			end

			local function format_yaml(start_line, end_line)
				local cmd = "'<,'>!yq eval 'sort_keys(.)' -"
				if start_line == 1 and end_line == vim.fn.line("$") then
					cmd = "%!yq eval 'sort_keys(.)' -"
				end
				vim.cmd(cmd)
			end

			vim.api.nvim_create_user_command("JSONFormat", function(opts)
				local start_line, end_line
				if opts.range == 2 then
					start_line = opts.line1
					end_line = opts.line2
				else
					start_line = 1
					end_line = vim.fn.line("$")
				end

				format_json(start_line, end_line)
			end, { range = true })

			vim.api.nvim_create_user_command("YAMLFormat", function(opts)
				local start_line, end_line
				if opts.range == 2 then
					start_line = opts.line1
					end_line = opts.line2
				else
					start_line = 1
					end_line = vim.fn.line("$")
				end

				format_yaml(start_line, end_line)
			end, { range = true })
		end,
	},
}

return M

