local M = {}
local markdown_filetypes = {
	"markdown",
}

M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		commit = "a1b0988f5ab26698afb56b9c2f0525a4de1195c1",
		dependencies = { "3rd/image.nvim" },
		ft = markdown_filetypes,
		config = function()
			require("render-markdown").setup({
				anti_conceal = {
					enabled = true, -- Enable anti-conceal for better folding protection
				},
				code = {
					language_icon = false,
					language_name = false,
				},
				file_types = markdown_filetypes,
				render_modes = true,
				sign = {
					enabled = false,
				},
				completions = {
					lsp = {
						enabled = true,
					},
				},
			})

			-- Enhanced autocmd for markdown files with better conditions
			vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufWinEnter" }, {
				pattern = "markdown",
				callback = function(args)
					local bufnr = args.buf
					local winid = vim.api.nvim_get_current_win()
					local config = vim.api.nvim_win_get_config(winid)

					-- Always ensure numbercolumn is available for folding
					vim.api.nvim_set_option_value("number", false, { win = winid })
					vim.api.nvim_set_option_value("relativenumber", false, { win = winid })

					-- Handle signcolumn based on window type
					if config.relative ~= "" then
						-- Floating window - disable signcolumn but add padding
						vim.api.nvim_set_option_value("signcolumn", "no", { win = winid })
						-- Add left padding for floating windows
						vim.api.nvim_set_option_value("foldcolumn", "2", { win = winid })
					else
						-- Regular window - keep minimal signcolumn for folding
						vim.api.nvim_set_option_value("signcolumn", "auto:1", { win = winid })
					end

					-- Ensure folding works properly
					vim.api.nvim_set_option_value("foldenable", true, { buf = bufnr })
					vim.api.nvim_set_option_value("foldmethod", "expr", { buf = bufnr })
					vim.api.nvim_set_option_value("foldexpr", "nvim_treesitter#foldexpr()", { buf = bufnr })
				end,
			})

			-- Additional autocmd for when entering any window to handle dynamic cases
			vim.api.nvim_create_autocmd("WinEnter", {
				callback = function()
					if vim.bo.filetype == "markdown" then
						local winid = vim.api.nvim_get_current_win()
						local config = vim.api.nvim_win_get_config(winid)

						-- Handle nofile buffers (like goose.nvim) specially
						if vim.bo.buftype == "nofile" or config.relative ~= "" then
							vim.api.nvim_set_option_value("signcolumn", "no", { win = winid })
							-- Increase foldcolumn for better padding in nofile/floating windows
							vim.api.nvim_set_option_value("foldcolumn", "3", { win = winid })
						else
							vim.api.nvim_set_option_value("signcolumn", "auto:1", { win = winid })
							vim.api.nvim_set_option_value("foldcolumn", "1", { win = winid })
						end
					end
				end,
			})

			-- Handle buffer type changes (for dynamic buffers)
			vim.api.nvim_create_autocmd("OptionSet", {
				pattern = "buftype",
				callback = function()
					if vim.bo.filetype == "markdown" then
						local winid = vim.api.nvim_get_current_win()

						if vim.bo.buftype == "nofile" then
							vim.api.nvim_set_option_value("signcolumn", "no", { win = winid })
							vim.api.nvim_set_option_value("foldcolumn", "3", { win = winid })
						end
					end
				end,
			})
		end,
	},
}

return M
