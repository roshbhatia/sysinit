local M = {}

M.plugins = {
	{
		enabled = true,
		"aweis89/ai-terminals.nvim",
		dependencies = { "folke/snacks.nvim" },
		keys = {
			{
				"<leader>aa",
				function()
					require("ai-terminals").toggle("aider")
				end,
				mode = { "n", "v" },
				desc = "AI: Toggle Aider terminal",
			},
			{
				"<leader>as",
				function()
					local selection = require("ai-terminals").get_visual_selection_with_header()
					if selection then
						require("ai-terminals").send_term("aider", selection, { submit = false })
					end
				end,
				mode = { "v" },
				desc = "AI: Send selection to Aider",
			},
			{
				"<leader>ac",
				function()
					require("ai-terminals").aider_comment("AI!")
				end,
				desc = "AI: Add 'AI!' comment above line",
			},
			{
				"<leader>aq",
				function()
					require("ai-terminals").aider_comment("AI?")
				end,
				desc = "AI: Add 'AI?' comment above line",
			},
			{
				"<leader>ad",
				function()
					require("ai-terminals").aider_add_files(vim.fn.expand("%"))
				end,
				desc = "AI: Add current file to Aider",
			},
			{
				"<leader>ar",
				function()
					require("ai-terminals").aider_add_files(vim.fn.expand("%"), { read_only = true })
				end,
				desc = "AI: Add current file as read-only",
			},
			{
				"<leader>aL",
				function()
					require("ai-terminals").aider_add_buffers()
				end,
				desc = "AI: Add all listed buffers to Aider",
			},
			{
				"<leader>aD",
				function()
					require("ai-terminals").send_diagnostics("aider")
				end,
				mode = { "n", "v" },
				desc = "AI: Send diagnostics to Aider",
			},
			{
				"<leader>aR",
				function()
					require("ai-terminals").send_command_output("aider")
				end,
				desc = "AI: Run command and send output to Aider",
			},
			{
				"<leader>aV",
				function()
					require("ai-terminals").diff_changes()
				end,
				desc = "AI: Show diff (vimdiff)",
			},
			{
				"<leader>av",
				function()
					require("ai-terminals").diff_changes({ delta = true })
				end,
				desc = "AI: Show diff (delta)",
			},
			{
				"<leader>au",
				function()
					require("ai-terminals").revert_changes()
				end,
				desc = "AI: Revert changes from backup",
			},
			{
				"<leader>af",
				function()
					require("ai-terminals").focus()
				end,
				desc = "AI: Focus Aider terminal",
			},
			{
				"<leader>ax",
				function()
					require("ai-terminals").destroy_all()
				end,
				desc = "AI: Destroy Aider terminal",
			},
			{
				"<leader>aa",
				function()
					local node = require("neo-tree.sources.filesystem.commands").get_node_at_cursor()
					if node and node.path then
						require("ai-terminals").aider_add_files(node.path)
					end
				end,
				desc = "Add File from Tree to Aider",
				ft = "neo-tree",
			},
			{
				"<leader>ar",
				function()
					local node = require("neo-tree.sources.filesystem.commands").get_node_at_cursor()
					if node and node.path then
						require("ai-terminals").aider_add_files(node.path, { read_only = true })
					end
				end,
				desc = "Add File from Tree as read-only",
				ft = "neo-tree",
			},
		},
		opts = {
			terminals = {
				aider = {
					cmd = function()
						-- Start the Copilot API server if it's not already running
						local check_cmd = "curl -s -o /dev/null -w '%{http_code}' http://localhost:4141/v1/models"
						local status = tonumber(vim.fn.system(check_cmd)) or 0

						if status ~= 200 then
							-- Start the Copilot API server and wait for it to be ready
							vim.notify("Starting Copilot API server...", vim.log.levels.INFO)
							vim.fn.jobstart("npx copilot-api@latest start --port 4141 --wait --vision", {
								detach = true,
							})

							-- Give it a moment to start up
							vim.fn.system("sleep 2")
						end

						-- Return the Aider command with the proper configuration
						return "aider -c ~/.aider.nvim.copilot.conf.yml --" .. vim.o.background .. "-mode"
					end,
				},
			},
			default_position = "right",
			window_dimensions = {
				right = { width = 0.4, height = 1.0 },
				float = { width = 0.8, height = 0.7 },
				border = "rounded",
			},
			enable_diffing = true,
			show_diffs_on_leave = true,
			prompts = {
				explain_code = "Explain the selected code snippet.",
				refactor_code = "Refactor the selected code to improve readability and performance.",
			},
			prompt_keymaps = {
				{ key = "<leader>ae", term = "aider", prompt = "explain_code", desc = "AI: Explain code selection" },
				{
					key = "<leader>aref",
					term = "aider",
					prompt = "refactor_code",
					desc = "AI: Refactor code selection",
				},
			},
			terminal_keymaps = {
				{ key = "<C-w>q", action = "close", desc = "Close terminal window", modes = "t" },
				{
					key = "<Esc>",
					action = function()
						vim.cmd("stopinsert")
					end,
					desc = "Exit terminal insert mode",
					modes = "t",
				},
			},
		},
		config = function(_, opts)
			require("ai-terminals").setup(opts)
		end,
	},
}

return M
