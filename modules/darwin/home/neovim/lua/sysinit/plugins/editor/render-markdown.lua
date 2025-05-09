local M = {}

M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown", "Avante" },
		config = function()
			-- Create a namespace for mermaid diagram rendering
			local ns_id = vim.api.nvim_create_namespace("mermaid_inline_render")

			-- Global storage for diagram information across buffers
			local buffer_diagrams = {}

			-- Setup the single autocmd for all buffers
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
				pattern = { "*.md", "*.markdown", "*.Avante" },
				callback = function()
					-- Get current buffer
					local buf = vim.api.nvim_get_current_buf()
					local diagrams = buffer_diagrams[buf]

					-- If no diagrams for this buffer, do nothing
					if not diagrams then
						return
					end

					-- Clear previous renders
					vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

					-- Get current cursor position
					local cursor = vim.api.nvim_win_get_cursor(0)
					local cursor_row = cursor[1] - 1 -- Convert to 0-indexed

					-- Check cursor position relative to diagrams
					for _, diagram in ipairs(diagrams) do
						-- If cursor is not inside this block, render the diagram
						local is_inside_block = cursor_row >= diagram.start_row and cursor_row <= diagram.end_row

						if not is_inside_block and vim.fn.filereadable(diagram.output_file) == 1 then
							-- Create a temporary file to hold the imgcat output
							local temp_output = os.tmpname()

							-- Run imgcat and capture its output to the temp file
							local imgcat_cmd =
								string.format("wezterm imgcat --width 80 %s > %s", diagram.output_file, temp_output)
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
									vim.api.nvim_buf_set_extmark(buf, ns_id, diagram.end_row, 0, {
										virt_lines = lines,
										virt_lines_above = false,
									})
								end
							end
						end
					end
				end,
			})

			-- Configure the plugin
			require("render-markdown").setup({
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

							-- Initialize buffer diagrams if not already done
							if not buffer_diagrams[ctx.buf] then
								buffer_diagrams[ctx.buf] = {}
							end

							-- Clear previous diagrams for this buffer
							buffer_diagrams[ctx.buf] = {}

							-- Setup the storage directory
							local buffer_name = vim.fn.bufname(ctx.buf):gsub("[^%w]", "_")
							local base_dir = "/tmp/nvim/render-markdown/" .. buffer_name
							vim.fn.mkdir(base_dir, "p")

							-- Function to check if a node is a mermaid code block
							local function is_mermaid_block(node)
								if node:type() ~= "fenced_code_block" then
									return false
								end
								local info_string = node:child(0)
								if not info_string then
									return false
								end

								local text = vim.treesitter.query.get_node_text(info_string, ctx.buf)
								return text and text:match("^```%s*mermaid") ~= nil
							end

							-- Function to generate diagram SVG from content
							local function generate_diagram(content)
								-- Create a unique hash for this diagram content
								local hash = vim.fn.sha256(content)

								-- Define output file path
								local output_file = string.format("%s/%s.svg", base_dir, hash)

								-- Generate SVG if it doesn't exist
								if vim.fn.filereadable(output_file) ~= 1 then
									-- Write content to a temp file (clean mermaid content without markdown fences)
									local clean_content = content:gsub("^```%s*mermaid\n", ""):gsub("\n```%s*$", "")
									local temp_file = string.format("/tmp/mermaid_%s.mmd", hash)
									local file = io.open(temp_file, "w")
									if file then
										file:write(clean_content)
										file:close()

										-- Generate SVG using mermaid CLI
										local cmd = string.format("mmdc -i %s -o %s", temp_file, output_file)
										vim.fn.system(cmd)

										-- Clean up
										os.remove(temp_file)
									end
								end

								return output_file
							end

							-- Scan for mermaid blocks
							for _, node in ipairs(ctx.root:iter_children()) do
								if is_mermaid_block(node) then
									local start_row, _, end_row, _ = node:range()
									local content = vim.treesitter.query.get_node_text(node, ctx.buf)

									-- Generate the diagram
									local output_file = generate_diagram(content)

									-- Store diagram info for the global autocmd
									table.insert(buffer_diagrams[ctx.buf], {
										start_row = start_row,
										end_row = end_row,
										output_file = output_file,
									})

									-- Add a mark to indicate there's a diagram
									table.insert(marks, {
										start_row = end_row,
										start_col = 0,
										opts = {
											virt_text = { { "▼ Mermaid Diagram", "Comment" } },
											virt_text_pos = "eol",
										},
									})
								end
							end

							return marks
						end,
					},
				},
			})

			-- Clear diagrams when buffer is closed
			vim.api.nvim_create_autocmd("BufDelete", {
				callback = function(args)
					buffer_diagrams[args.buf] = nil
				end,
			})
		end,
	},
}

return M
