local M = {}

M.plugins = {
	{
		"tamton-aquib/staline.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		lazy = false,
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
						"file_size",
						"line_column",
						"cool_symbol",
					},
				},
				defaults = {
					cool_symbol = "󱄅",
					expand_null_ls = false,
					true_colors = true,
					line_column = ":%c [%l/%L]",
					lsp_client_symbol = "",
					lsp_client_character_length = 40,
					file_size_suffix = true,
					branch_symbol = " ",
				},
				mode_colors = {
					n = "#d19bc4", -- Muted pink for normal mode
					i = "#7fb3aa", -- Desaturated teal for insert mode
					c = "#9da3d4", -- Soft lavender for command mode
					v = "#7287c7", -- Muted blue for visual mode
					V = "#7287c7", -- Muted blue for visual line mode
					[""] = "#7287c7", -- Muted blue for visual block mode
					R = "#c7a584", -- Muted peach for replace mode
					r = "#c7a584", -- Muted peach for replace mode
					s = "#d4c481", -- Subtle yellow for select mode
					S = "#d4c481", -- Subtle yellow for select mode
					t = "#9cb380", -- Washed out green for terminal mode
				},
			})
		end,
	},
}

return M
