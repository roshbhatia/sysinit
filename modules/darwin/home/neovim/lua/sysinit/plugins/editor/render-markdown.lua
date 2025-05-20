local M = {}

local markdown_filetypes = {
	"markdown",
	"Avante",
	"codecompanion",
}

M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		commit = "a1b0988f5ab26698afb56b9c2f0525a4de1195c1",
		dependencies = { "3rd/image.nvim" },
		ft = markdown_filetypes,
		config = function()
			-- Create namespaces for mermaid handling
			local mermaid_ns_id = vim.api.nvim_create_namespace("mermaid_inline_render")
			local mermaid_fold_ns_id = vim.api.nvim_create_namespace("mermaid_fold")

			-- Global storage for diagram information across buffers
			local buffer_diagrams = {}

			-- Set up the plugin
			require("render-markdown").setup({
				anti_conceal = {
					enabled = false,
				},
				file_types = markdown_filetypes,
				render_modes = true, -- Render in ALL modes
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
							local buf = ctx.buf

							-- Initialize buffer diagrams if not already done
							if not buffer_diagrams[buf] then
								buffer_diagrams[buf] = {}
							end

							-- Clear previous diagrams for this buffer
							buffer_diagrams[buf] = {}

							-- Setup the storage directory
							local buffer_name = vim.fn.bufname(buf):gsub("[^%w]", "_")
							local base_dir = "/tmp/nvim/render-markdown/" .. buffer_name
							vim.fn.mkdir(base_dir, "p")

							-- Function to check if node is a mermaid block
							local function is_mermaid_block(node)
								if node:type() ~= "fenced_code_block" then
									return false
								end

								local info_string = node:child(0)
								if not info_string then
									return false
								end

								local text = vim.treesitter.query.get_node_text(info_string, buf)
								return text and text:match("^```%s*mermaid") ~= nil
							end

							-- Function to generate SVG from mermaid content
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
									local content = vim.treesitter.query.get_node_text(node, buf)

									-- Generate the diagram
									local output_file = generate_diagram(content)

									-- Store diagram info globally
									table.insert(buffer_diagrams[buf], {
										start_row = start_row,
										end_row = end_row,
										content = content,
										output_file = output_file,
										image_id = nil, -- Will store the image.nvim ID
									})

									-- Add a mark to indicate a diagram
									table.insert(marks, {
										start_row = start_row,
										start_col = 0,
										opts = {
											virt_text = { { "▼ Mermaid Diagram", "Comment" } },
											virt_text_pos = "overlay",
										},
									})
								end
							end

							-- Function to render or hide diagrams based on cursor position
							local function update_diagrams()
								local image = require("image")

								-- Get current cursor position
								local cursor = vim.api.nvim_win_get_cursor(0)
								local cursor_row = cursor[1] - 1 -- Convert to 0-indexed

								-- Check cursor position relative to diagrams
								for _, diagram in ipairs(buffer_diagrams[buf] or {}) do
									-- Determine if cursor is inside this block
									local is_inside_block = cursor_row >= diagram.start_row
										and cursor_row <= diagram.end_row

									-- Clear any existing fold for this block
									vim.api.nvim_buf_clear_namespace(
										buf,
										mermaid_fold_ns_id,
										diagram.start_row,
										diagram.end_row + 1
									)

									-- If outside the block, fold it and show image
									if not is_inside_block then
										-- Fold the code block
										vim.api.nvim_buf_set_extmark(buf, mermaid_fold_ns_id, diagram.start_row, 0, {
											end_row = diagram.end_row,
											end_col = 0,
											conceal = true,
										})

										-- If we haven't created an image for this diagram yet, create it
										if not diagram.image_id then
											-- Get window dimensions
											local win_width = vim.api.nvim_win_get_width(0) - 10

											-- Render the image at the start of the diagram
											local options = {
												window = {
													width = win_width, -- almost full window width
													height = 0, -- auto height
													x = 0, -- left edge of window
													y = 0, -- under the fold mark
													buffer = buf,
													row = diagram.start_row,
													col = 0,
													zindex = 50, -- make sure it's on top
												},
												render = {
													mode = "normal", -- normal mode for SVG rendering
													transparency = true, -- preserve transparency
												},
											}

											-- Create the image using image.nvim
											diagram.image_id = image.from_file(diagram.output_file, options)
										else
											-- Show existing image
											image.show(diagram.image_id)
										end
									else
										-- Inside the block, hide the image if it exists
										if diagram.image_id then
											require("image").hide(diagram.image_id)
										end
									end
								end
							end

							-- Setup cursor movement detection (only once per buffer)
							if not vim.b[buf].mermaid_autocmd_set then
								vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
									buffer = buf,
									callback = update_diagrams,
								})

								-- Update diagrams immediately
								vim.defer_fn(update_diagrams, 100)

								-- Mark that we've set up the autocmd
								vim.b[buf].mermaid_autocmd_set = true
							end

							return marks
						end,
					},
				},
			})

			-- Clean up diagrams when buffer is closed
			vim.api.nvim_create_autocmd("BufDelete", {
				callback = function(args)
					if buffer_diagrams[args.buf] then
						local image = require("image")
						for _, diagram in ipairs(buffer_diagrams[args.buf]) do
							if diagram.image_id then
								image.clear(diagram.image_id)
							end
						end
					end

					-- Clean up the buffer diagrams
					buffer_diagrams[args.buf] = nil
				end,
			})

			-- Signcolumn on markdown files sometimes causes issues
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function()
					vim.opt_local.signcolumn = "no"
				end,
			})
		end,
	},
}

return M
