M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown", "Avante" },
		opts = {
			file_types = { "markdown", "mermaid", "Avante" },
			latex = {
				enabled = false,
			},
			html = {
				enabled = false,
			},
			custom_handlers = {
				mermaid = {
					parse = function(ctx)
						local marks = {}
						local buffer_name = vim.fn.bufname(ctx.buf):gsub("[^%w]", "_")
						local base_dir = "/tmp/nvim/render-markdown/" .. buffer_name
						vim.fn.mkdir(base_dir, "p")

						for _, node in ipairs(ctx.root:iter_children()) do
							-- Get the node range and content
							local start_row, _, end_row, _ = node:range()
							local content = vim.treesitter.query.get_node_text(node, ctx.buf)

							-- Create a unique hash for each diagram
							local hash = vim.fn.sha256(content)
							local output_file = string.format("%s/%s.svg", base_dir, hash)

							-- Write content to a temporary file
							local temp_file = "/tmp/diagram_" .. hash .. ".mmd"
							local file = io.open(temp_file, "w")
							if file then
								file:write(content)
								file:close()
							end

							-- Render the mermaid diagram to SVG
							vim.fn.system({ "mmdc", "-i", temp_file, "-o", output_file })

							-- Clean up temp file
							vim.fn.delete(temp_file)

							-- Add extmark outside of the mermaid block
							marks[#marks + 1] = {
								conceal = true,
								start_row = end_row + 1, -- Position after the mermaid block
								start_col = 0,
								opts = {
									end_row = end_row + 1,
									virt_lines = {
										{
											{ "", "" },
											{ "Mermaid Diagram: ", "Comment" },
										},
									},
									virt_lines_above = false,
								},
							}

							-- Add the image using virt_text_win_col
							if vim.fn.filereadable(output_file) == 1 then
								marks[#marks + 1] = {
									conceal = false,
									start_row = end_row + 1,
									start_col = 0,
									opts = {
										end_row = end_row + 1,
										virt_lines = {
											{
												{ "", "" },
												{ "󰋩 ", "Special" },
												{ "[Image: " .. output_file .. "]", "DiagnosticHint" },
											},
										},
										virt_lines_above = false,
									},
								}

								-- Use image viewer when outside mermaid blocks
								vim.api.nvim_create_autocmd("CursorMoved", {
									buffer = ctx.buf,
									callback = function()
										local cursor = vim.api.nvim_win_get_cursor(0)
										local cursor_row = cursor[1] - 1

										-- Check if cursor is outside mermaid block but on a diagram line
										if cursor_row == end_row + 1 then
											-- Close any existing floating windows
											for _, win in ipairs(vim.api.nvim_list_wins()) do
												if vim.api.nvim_win_get_config(win).relative ~= "" then
													vim.api.nvim_win_close(win, true)
												end
											end

											-- Create a new floating window with the SVG image
											if vim.fn.executable("ueberzug") == 1 then
												-- Use ueberzug for proper image rendering
												local width = 60 -- Adjust based on your preference
												local height = 20 -- Adjust based on your preference
												local buf = vim.api.nvim_create_buf(false, true)

												local win = vim.api.nvim_open_win(buf, false, {
													relative = "cursor",
													row = 1,
													col = 0,
													width = width,
													height = height,
													style = "minimal",
													border = "rounded",
												})

												vim.fn.jobstart(
													{ "ueberzug", "layer", "--silent", "--parse", "json" },
													{
														stdin = {
															'{"action": "add", "identifier": "mermaid-preview", "x": 0, "y": 0, "path": "'
																.. output_file
																.. '", "width": '
																.. width
																.. ', "height": '
																.. height
																.. "}",
														},
														on_exit = function()
															vim.api.nvim_win_close(win, true)
														end,
													}
												)
											else
												-- Fallback to terminal image viewer if available
												local term_buf = vim.api.nvim_create_buf(false, true)
												vim.api.nvim_open_win(term_buf, false, {
													relative = "cursor",
													row = 1,
													col = 0,
													width = 60,
													height = 20,
													style = "minimal",
													border = "rounded",
												})
												vim.fn.termopen("kitty +kitten icat " .. output_file)
											end
										end
									end,
								})
							end
						end

						return marks
					end,
				},
			},
		},
	},
}

return M
