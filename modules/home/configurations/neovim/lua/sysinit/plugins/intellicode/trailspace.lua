local M = {}

M.plugins = {
	{
		"echasnovski/mini.trailspace",
		event = "BufWritePre",
		config = function()
			local trim_whitespace_enabled = true
			local whitespace_augroup = vim.api.nvim_create_augroup("whitespace_trim_augroup", {
				clear = true,
			})

			local function ensure_trailing_newline()
				local last_line = vim.fn.line("$")
				local last_line_text = vim.fn.getline(last_line)

				if last_line_text ~= "" then
					vim.fn.append(last_line, "")
				elseif last_line > 1 and vim.fn.getline(last_line - 1) == "" then
					while last_line > 1 and vim.fn.getline(last_line - 1) == "" do
						vim.api.nvim_buf_set_lines(0, last_line - 1, last_line, false, {})
						last_line = last_line - 1
					end
				end
			end

			local function trim_trailing_whitespace()
				require("mini.trailspace").trim()
			end

			local function trim_whitespace_and_ensure_newline()
				if not trim_whitespace_enabled then
					return
				end
				local cursor_pos = vim.fn.getpos(".")
				trim_trailing_whitespace()
				ensure_trailing_newline()
				vim.fn.setpos(".", cursor_pos)
			end

			vim.api.nvim_create_autocmd("BufWritePre", {
				group = whitespace_augroup,
				callback = trim_whitespace_and_ensure_newline,
			})

			vim.api.nvim_create_user_command("ToggleWhitespaceTrim", function()
				trim_whitespace_enabled = not trim_whitespace_enabled
				if trim_whitespace_enabled then
					vim.api.nvim_clear_autocmds({
						group = whitespace_augroup,
					})
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = whitespace_augroup,
						callback = trim_whitespace_and_ensure_newline,
					})
					vim.notify("Automatic whitespace trimming enabled", vim.log.levels.INFO)
				else
					vim.api.nvim_clear_autocmds({
						group = whitespace_augroup,
					})
					vim.notify("Automatic whitespace trimming disabled", vim.log.levels.INFO)
				end
			end, {})
		end,
	},
}

return M

