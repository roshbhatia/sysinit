local M = {}
M.plugins = {
	{
		"aweis89/ai-terminals.nvim",
		commit = "09aa0978a83efda9b810b1b0297683de5bffe46c",
		dependencies = {
			"folke/snacks.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			vim.o.autoread = true
			require("ai-terminals").setup({
				terminals = {
					aider = {
						cmd = "aider -c ~/.aider.nvim.copilot.conf.yml",
					},
					goose = nil,
					aichat = nil,
					claude = nil,
					kode = nil,
				},
				show_diffs_on_leave = { delta = true },
				default_position = "right",
				terminal_keymaps = {
					{
						key = "<Esc>",
						action = function()
							vim.cmd("stopinsert")
						end,
						desc = "Exit terminal insert mode",
						modes = "t",
					},
				},
			})

			-- Auto-add files
			vim.api.nvim_create_autocmd("BufEnter", {
				callback = function()
					local bufname = vim.fn.expand("%")
					if bufname == "" or bufname:match("^%s*$") or vim.bo.buftype ~= "" then
						return
					end
					require("ai-terminals").aider_add_files(bufname)
				end,
				group = vim.api.nvim_create_augroup("AiderAutoAdd", { clear = true }),
			})

			-- Telescope integration
			local telescope_loaded, telescope = pcall(require, "telescope")
			if telescope_loaded then
				telescope.setup({
					defaults = {
						mappings = {
							i = {
								["<C-a>"] = function(prompt_bufnr)
									local action_state = require("telescope.actions.state")
									local selection = action_state.get_selected_entry()
									if selection and selection.filename then
										require("ai-terminals").aider_add_files(selection.filename)
										require("telescope.actions").close(prompt_bufnr)
									end
								end,
							},
						},
					},
				})
			end
		end,
		keys = function()
			return {
				{
					"<leader>aa",
					function()
						require("ai-terminals").toggle("aider")
					end,
					mode = { "n", "v" },
					desc = "Toggle Aider terminal (sends selection in visual mode)",
				},
				{
					"<leader>ac",
					function()
						vim.ui.input({ prompt = "Enter comment (AI!): " }, function(comment_text)
							if comment_text then
								require("ai-terminals").aider_comment("AI! " .. comment_text)
							end
						end)
					end,
					desc = "Add 'AI!' comment above line",
				},
				{
					"<leader>aC",
					function()
						vim.ui.input({ prompt = "Enter comment (AI?): " }, function(comment_text)
							if comment_text then
								require("ai-terminals").aider_comment("AI? " .. comment_text)
							end
						end)
					end,
					desc = "Add 'AI?' comment above line",
				},
				{
					"<leader>al",
					function()
						require("ai-terminals").aider_add_files(vim.fn.expand("%"))
					end,
					desc = "Add current file to Aider (/add)",
				},
				{
					"<leader>aR",
					function()
						require("ai-terminals").aider_add_files(vim.fn.expand("%"), { read_only = true })
					end,
					desc = "Add current file to Aider (read-only)",
				},
				{
					"<leader>af",
					function()
						require("telescope.builtin").find_files({
							attach_mappings = function(_, map)
								map("i", "<CR>", function(prompt_bufnr)
									local action_state = require("telescope.actions.state")
									local selection = action_state.get_selected_entry()
									require("telescope.actions").close(prompt_bufnr)
									if selection then
										require("ai-terminals").aider_add_files(selection.value)
									end
								end)
								return true
							end,
						})
					end,
					desc = "Find and add file to Aider",
				},
				{
					"<leader>ad",
					function()
						require("ai-terminals").send_diagnostics("aider")
					end,
					mode = { "n", "v" },
					desc = "Send diagnostics to Aider",
				},
				{
					"<leader>ax",
					function()
						require("ai-terminals").destroy_all()
					end,
					desc = "Destroy all AI terminals (closes windows, stops processes)",
				},
				{
					"<leader>az",
					function()
						require("ai-terminals").destroy_all()
						vim.defer_fn(function()
							require("ai-terminals").toggle("aider")
						end, 100)
					end,
					desc = "Reset AI terminal (kill and restart)",
				},
				{
					"<leader>ak",
					function()
						local term = require("ai-terminals.terminal").get_terminal("aider")
						if term then
							term:send("\x0C") -- Send Ctrl+L to clear the terminal view
						end
					end,
					desc = "Clear terminal view (preserve scrollback)",
				},
				{
					"<leader>aD",
					function()
						require("ai-terminals").diff_changes({ delta = true })
					end,
					desc = "Show diff (delta)",
				},
				{
					"<leader>aV",
					function()
						require("ai-terminals").revert_changes()
					end,
					desc = "Revert changes from backup",
				},
			}
		end,
	},
}

return M

