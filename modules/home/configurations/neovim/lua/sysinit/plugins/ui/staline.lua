local M = {}

M.plugins = {
	{
		"tamton-aquib/staline.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		event = {
			"BufEnter",
			"User AlphaClosed",
		},
		config = function()
			require("staline").setup({
				sections = {
					left = {
						"mode",
						"branch",
						" ",
						"lsp",
					},
					mid = {
						{
							"Staline",
							function()
								local ok, git_blame = pcall(require, "gitblame")
								if not ok then
									return ""
								end

								if git_blame.is_blame_text_available and git_blame.is_blame_text_available() then
									local text = git_blame.get_current_blame_text()
									local by_index = string.find(text, " by ")
									if by_index then
										local msg = string.sub(text, 1, by_index - 1)
										local rest = string.sub(text, by_index)
										if #msg > 32 then
											msg = string.sub(msg, 1, 29) .. "..."
										end
										return msg .. rest
									else
										if #text > 32 then
											return string.sub(text, 1, 29) .. "..."
										else
											return text
										end
									end
								else
									return ""
								end
							end,
						},
					},
					right = {
						"line_column",
						"cool_symbol",
					},
				},
				lsp_symbols = {
					Error = " ",
					Hint = " ",
					Info = " ",
					Warn = " ",
				},
				defaults = {
					cool_symbol = "󱄅",
					expand_null_ls = false,
					true_colors = true,
					line_column = ":%c [%l/%L]",
					lsp_client_symbol = "",
					lsp_client_character_length = 40,
				},
			})
		end,
	},
}

return M
