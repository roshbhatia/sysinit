dofile = vim.api.nvim_create_autocmd or vim.api.nvim_command

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = "*.yaml,*.yml",
	callback = function(args)
		local bufnr = args.buf
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, math.min(100, vim.api.nvim_buf_line_count(bufnr)), false)
		for _, line in ipairs(lines) do
			if line:match("kind:%s*Composition") or line:match("kind:%s*CompositeResourceDefinition") then
				vim.api.nvim_buf_set_option(bufnr, "filetype", "yaml.crossplane")
				return
			end
		end
	end,
})

