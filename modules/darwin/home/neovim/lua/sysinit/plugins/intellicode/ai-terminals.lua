local M = {}

M.plugins = {

	{
		"aweis89/ai-terminals.nvim",
		enabled = true,
		event = "VeryLazy",
		dependencies = { "folke/snacks.nvim" },
		config = function()
			local function get_file_context()
				-- Gets the current filename and its content
				local filepath = vim.api.nvim_buf_get_name(0)
				local file_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
				local repo_path = vim.fn.systemlist("git rev-parse --show-toplevel")[1] or "Unknown repo"

				return string.format("File: %s\nRepo: %s\n%s", filepath, repo_path, file_content)
			end

			local function get_lsp_diagnostics()
				local diagnostics = vim.diagnostic.get(0) -- Get diagnostics for the current buffer only
				local formatted_diagnostics = {}

				for _, diag in ipairs(diagnostics) do
					table.insert(
						formatted_diagnostics,
						string.format(
							"[%s] Line %d Col %d: %s",
							diag.severity,
							diag.lnum + 1,
							diag.col + 1,
							diag.message
						)
					)
				end

				return table.concat(formatted_diagnostics, "\n")
			end

			require("ai-terminals").setup({
				terminals = {
					goose = {
						cmd = function()
							return "GOOSE_CLI_THEME=dark goose"
						end,
					},
					aider = nil,
					claude = nil,
					aichat = nil,
					kode = nil,
				},
				default_position = "right",
				enable_diffing = true,
				show_diffs_on_leave = { delta = true },
				prompt_keymaps = {
					{
						key = "<leader>ae",
						term = "goose",
						prompt = function()
							return string.format("Explain the following code:\n%s", get_file_context())
						end,
						desc = "Copilot: Explain the file or selection",
						include_selection = true,
						submit = true,
					},
					{
						key = "<leader>ad",
						term = "goose",
						prompt = function()
							return string.format("Here are the diagnostics for the file:\n%s", get_lsp_diagnostics())
						end,
						desc = "Copilot: Send diagnostics with context",
						include_selection = false,
						submit = true,
					},
					{
						key = "<leader>at",
						term = "goose",
						prompt = function()
							return string.format("Write tests for the following code:\n%s", get_file_context())
						end,
						desc = "Copilot: Write tests for the code",
						include_selection = true,
						submit = true,
					},
					{
						key = "<leader>ar",
						term = "goose",
						prompt = function()
							return string.format("Refactor the following code:\n%s", get_file_context())
						end,
						desc = "Copilot: Refactor the code",
						include_selection = true,
						submit = true,
					},
				},
			})
		end,
		keys = function()
			return {
				{
					"<leader>aa",
					function()
						require("ai-terminals").toggle("goose")
					end,
					desc = "Copilot: Toggle chat",
					mode = { "n", "v" },
				},
				{
					"<leader>aA",
					function()
						local repo_path = vim.fn.systemlist("git rev-parse --show-toplevel")[1] or "Unknown repo"
						local msg = string.format("Opening a new chat session for repository: %s", repo_path)
						require("ai-terminals").send_command_output("goose", msg)
					end,
					desc = "Copilot: Open a new chat session",
					mode = { "n" },
				},
				{
					"<leader>af",
					function()
						require("ai-terminals").focus()
					end,
					desc = "Copilot: Focus the chat",
					mode = { "n" },
				},
				{
					"<leader>ax",
					function()
						require("ai-terminals").destroy_all()
					end,
					desc = "Copilot: Destroy all AI terminals",
					mode = { "n" },
				},
			}
		end,
	},
}

return M
