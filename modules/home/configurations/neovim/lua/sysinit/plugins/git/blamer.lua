local M = {}

M.plugins = {
	{
		"f-person/git-blame.nvim",
		event = "VeryLazy",
		config = function()
			-- Disable default virtual text display mechanism
			vim.g.gitblame_display_virtual_text = 0

			require("gitblame").setup({
				enabled = true,
				message_template = "<summary> by <author> in <<sha>>",
			})

			local cursor_line_bg = vim.api.nvim_get_hl_by_name("CursorLine", true).background
			local normal_fg = vim.api.nvim_get_hl_by_name("Normal", true).foreground
			vim.g.gitblame_highlight_group = "gitblame"

			vim.api.nvim_set_hl(0, "gitblame", {
				fg = vim.fn.synIDattr(vim.fn.hlID("Comment"), "fg") or normal_fg,
				bg = cursor_line_bg or "NONE",
			})

			vim.g.gitblame_delay = 25

			-- Custom function to display git blame only if no virtualtext exists
			local git_blame = require("gitblame")

			-- Create autocmd to show git blame after cursor moves
			local blame_augroup = vim.api.nvim_create_augroup("CustomGitBlame", { clear = true })
			vim.api.nvim_create_autocmd("CursorMoved", {
				group = blame_augroup,
				callback = function()
					local bufnr = vim.api.nvim_get_current_buf()
					local row = vim.api.nvim_win_get_cursor(0)[1] - 1

					-- Check if line already has virtualtext from other sources
					local extmarks = vim.api.nvim_buf_get_extmarks(
						bufnr,
						-1, -- All namespaces except the gitblame one
						{ row, 0 },
						{ row, -1 },
						{ details = true }
					)

					-- Check if any of the extmarks have virtualtext
					local has_virtualtext = false
					for _, extmark in ipairs(extmarks) do
						-- Check if extmark has virtualtext
						if extmark[4] and extmark[4].virt_text then
							has_virtualtext = true
							break
						end
					end

					-- If no virtualtext exists, show git blame
					if not has_virtualtext and git_blame.is_blame_text_available() then
						local blame_text = git_blame.get_current_blame_text()
						if blame_text and blame_text ~= "" then
							local ns_id = vim.api.nvim_create_namespace("gitblame_custom")
							vim.api.nvim_buf_clear_namespace(bufnr, ns_id, row, row + 1)
							vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, 0, {
								virt_text = { { blame_text, "gitblame" } },
								virt_text_pos = "eol",
							})
						end
					end
				end,
			})

			vim.api.nvim_create_autocmd("BufEnter", {
				callback = function()
					local buf_name = vim.api.nvim_buf_get_name(0)
					if buf_name:match("%.md$") then
						vim.cmd("GitBlameDisable")
					else
						-- I care not for running this smartly.
						vim.cmd("GitBlameEnable")
					end
				end,
			})

			-- Clear our custom git blame virtualtext when entering insert mode
			vim.api.nvim_create_autocmd("InsertEnter", {
				callback = function()
					local bufnr = vim.api.nvim_get_current_buf()
					local ns_id = vim.api.nvim_create_namespace("gitblame_custom")
					vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
				end,
			})
		end,
		keys = function()
			return {
				{
					"<leader>gos",
					"<CMD>GitBlameCopyCommitURL<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Copy blame URL",
				},
				{
					"<leader>goo",
					"<CMD>GitBlameOpenFileURL<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Open blame URL",
				},
			}
		end,
	},
}

return M
