local M = {}

M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown", "Avante" },
		opts = {
			file_types = { "markdown", "mermaid", "Avante" },
			custom_handlers = {
				mermaid = {
					parse = function(ctx)
						local marks = {}
						local buffer_name = vim.fn.bufname(ctx.buf):gsub("[^%w]", "_")
						local base_dir = "/tmp/nvim/render-markdown/" .. buffer_name
						vim.fn.mkdir(base_dir, "p")

						-- Create a namespace for our extmarks
						local ns_id = vim.api.nvim_create_namespace("mermaid_inline_render")

						-- Store diagram info for autocmd
						local diagrams = {}

						-- Process mermaid blocks
						for _, node in ipairs(ctx.root:iter_children()) do
							local start_row, _, end_row, _ = node:range()
							local content = vim.treesitter.query.get_node_text(node, ctx.buf)

							-- Create a unique hash for this diagram content
							local hash = vim.fn.sha256(content)
							local output_file = string.format("%s/%s.svg", base_dir, hash)

							-- Generate SVG if it doesn't exist
							if vim.fn.filereadable(output_file) ~= 1 then
								-- Write content to a temp file
								local temp_file = string.format("/tmp/mermaid_%s.mmd", hash)
								local file = io.open(temp_file, "w")
								if file then
									file:write(content)
									file:close()

									-- Generate SVG using mermaid CLI
									local cmd = string.format("mmdc -i %s -o %s", temp_file, output_file)
									vim.fn.system(cmd)

									-- Clean up
									os.remove(temp_file)
								end
							end

							-- Store diagram info
							table.insert(diagrams, {
								start_row = start_row,
								end_row = end_row,
								hash = hash,
								output_file = output_file,
							})

							-- Add a mark at the end of the mermaid block for reference
							marks[#marks + 1] = {
								start_row = end_row,
								start_col = 0,
								opts = {
									virt_text = { { "▼ Mermaid Diagram", "Comment" } },
									virt_text_pos = "eol",
								},
							}
						end

						-- Create an imgcat renderer function
						local function render_imgcat(output_file, start_row, end_row)
							-- Create a temporary file to hold the imgcat output
							local temp_output = os.tmpname()

							-- Run imgcat and capture its output to the temp file
							local imgcat_cmd =
								string.format("wezterm imgcat %s --height 20 > %s", output_file, temp_output)
							vim.fn.system(imgcat_cmd)

							-- Read the imgcat output
							local file = io.open(temp_output, "r")
							if file then
								local imgcat_output = file:read("*all")
								file:close()
								os.remove(temp_output)

								-- Split the output into lines
								local lines = {}
								for line in imgcat_output:gmatch("[^\r\n]+") do
									table.insert(lines, { { line, "" } })
								end

								-- If we have output, add it as virtual lines after the mermaid block
								if #lines > 0 then
									vim.api.nvim_buf_set_extmark(ctx.buf, ns_id, end_row, 0, {
										virt_lines = lines,
										virt_lines_above = false,
									})
								end
							end
						end

						-- Setup auto command for cursor-based rendering
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
							buffer = ctx.buf,
							callback = function()
								-- Clear previous renders
								vim.api.nvim_buf_clear_namespace(ctx.buf, ns_id, 0, -1)

								-- Get current cursor position
								local cursor = vim.api.nvim_win_get_cursor(0)
								local cursor_row = cursor[1] - 1 -- Convert to 0-indexed

								-- Check cursor position relative to diagrams
								for _, diagram in ipairs(diagrams) do
									-- If cursor is not inside this block, render the diagram
									local is_inside_block = cursor_row >= diagram.start_row
										and cursor_row <= diagram.end_row

									if not is_inside_block and vim.fn.filereadable(diagram.output_file) == 1 then
										render_imgcat(diagram.output_file, diagram.start_row, diagram.end_row)
									end
								end
							end,
						})

						return marks
					end,
				},
			},
		},
	},
}

return M
