local M = {}

M.plugins = {
	{
		"Bekaboo/dropbar.nvim",
		dependencies = {
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		config = function()
			require("dropbar").setup({
				scrollbar = {
					enable = false,
				},
				icons = {
					ui = {
						bar = {
							separator = "  ",
							extends = "…",
						},
					},
				},
				menu = {
					preview = false,
				},
				bar = {
					pick = {
						pivots = "fjdkslaghrueiwoncmv",
					},
					enable = function(buf, win, _)
						if
							not vim.api.nvim_buf_is_valid(buf)
							or not vim.api.nvim_win_is_valid(win)
							or vim.fn.win_gettype(win) ~= ""
							or vim.wo[win].winbar ~= ""
							or vim.bo[buf].ft == "help"
						then
							return false
						end

						local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
						if stat and stat.size > 1024 * 1024 then
							return false
						end

						return vim.bo[buf].ft == "markdown"
							or vim.bo[buf].ft == "oil" -- enable in oil buffers
							or vim.bo[buf].ft == "fugitive" -- enable in fugitive buffers
							or pcall(vim.treesitter.get_parser, buf)
							or not vim.tbl_isempty(vim.lsp.get_clients({
								bufnr = buf,
								method = "textDocument/documentSymbol",
							}))
					end,
				},
				sources = {
					path = {
						relative_to = function(buf, win)
							-- Show full path in oil or fugitive buffers
							local bufname = vim.api.nvim_buf_get_name(buf)
							if vim.startswith(bufname, "oil://") or vim.startswith(bufname, "fugitive://") then
								local root = bufname:gsub("^%S+://", "", 1)
								while root and root ~= vim.fs.dirname(root) do
									root = vim.fs.dirname(root)
								end
								return root
							end

							local ok, cwd = pcall(vim.fn.getcwd, win)
							return ok and cwd or vim.fn.getcwd()
						end,
					},
				},
			})
		end,
		keys = function()
			local dropbar_api = require("dropbar.api")
			return {
				{
					"<leader>fx",
					dropbar_api.pick,
					mode = "n",
					desc = "Symbols in winbar",
				},
			}
		end,
	},
}

return M

