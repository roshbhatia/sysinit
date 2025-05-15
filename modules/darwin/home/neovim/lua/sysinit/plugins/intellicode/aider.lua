local M = {}

local function get_github_copilot_token()
	local apps_json_path = vim.fn.expand("~/.config/github-copilot/apps.json")

	if vim.fn.filereadable(apps_json_path) ~= 1 then
		vim.notify("GitHub Copilot apps.json file not found", vim.log.levels.ERROR)
		return nil
	end

	local content = vim.fn.readfile(apps_json_path)
	local json_str = table.concat(content, "\n")

	local success, parsed = pcall(vim.fn.json_decode, json_str)
	if not success then
		vim.notify("Failed to parse GitHub Copilot apps.json", vim.log.levels.ERROR)
		return nil
	end

	-- Find the first key that matches GitHub App ID pattern
	for key, value in pairs(parsed) do
		-- Look for entries with the structure we need
		if type(value) == "table" and value.oauth_token and value.githubAppId then
			return value.oauth_token
		end
	end

	vim.notify("No valid GitHub Copilot token found in apps.json", vim.log.levels.WARN)
	return nil
end

M.plugins = {
	{
		"GeorgesAlkhouri/nvim-aider",
		cmd = "BufEnter",
		keys = {
			{ "<leader>aa", "<cmd>Aider toggle<cr>", desc = "Copilot: Toggle chat" },
			{ "<leader>as", "<cmd>Aider send<cr>", desc = "Copilot: Send to chat", mode = { "n", "v" } },
			{ "<leader>ai", "<cmd>Aider command<cr>", desc = "Copilot: Chat commands" },
			{ "<leader>ab", "<cmd>Aider buffer<cr>", desc = "Copilot: Send buffer" },
			{ "<leader>ad", "<cmd>Aider add<cr>", desc = "Copilot: Add file" },
			{ "<leader>ar", "<cmd>Aider drop<cr>", desc = "Copilot: Drop file" },
			{ "<leader>aR", "<cmd>Aider reset<cr>", desc = "Copilot: Reset session" },
			{ "<leader>aa", "<cmd>AiderTreeAddFile<cr>", desc = "Add File from Tree to Aider", ft = "neo-tree" },
			{ "<leader>ad", "<cmd>AiderTreeDropFile<cr>", desc = "Drop File from Tree from Aider", ft = "neo-tree" },
		},
		dependencies = {
			"folke/snacks.nvim",
			"catppuccin/nvim",
			"zbirenbaum/copilot.lua",
		},
		config = function()
			-- aider \
			--no-auto-commits \
			--pretty \
			--stream \
			--no-show-model-warnings \
			--openai-api-base https://api.githubcopilot.com \
			--model openai/claude-3.5-sonnet \
			--weak-model openai/gpt-4o \
			--openai-api-key $(curl -s -H "Authorization: Bearer $(cat ~/.config/github-copilot/apps.json | jq -r 'to_entries[0].value.oauth_token')" "https://api.github.com/copilot_internal/v2/token" | jq -r '.token') \
			--no-gitignore \
			--no-attribute-author \
			--no-attribute-committer \
			--code-theme github-dark \
			--set-env accept=application/json \
			--set-env editor-version=Neovim/0.6.1 \
			--set-env editor-plugin-version=copilot.vim/1.16.0 \
			--set-env user-agent=GithubCopilot/1.155.0
			require("nvim_aider").setup({
				aider_cmd = "aider",
				args = {
					"--no-auto-commits",
					"--pretty",
					"--stream",
					-- Our options to hackily work with github copilot, which uses the openai auth method.
					"--no-show-model-warnings",
					"--openai-api-base https://api.githubcopilot.com",
					"--model openai/claude-3.5-sonnet", -- github_copilot/claude-3.5-sonnet
					"--weak-model openai/gpt-4o", -- github_copilot/gpt-4o",
					string.format("--openai-api-key %s", get_github_copilot_token()),
					-- extras
					"--no-gitignore",
					"--no-attribute-author",
					"--no-attribute-committer",
					"--code-theme github-dark",
					"--set-env accept=application/json",
					"--set-env Editor-Version=Neovim/0.6.1",
					"--set-env editor-plugin-version=copilot.vim/1.16.0",
					"--set-env content-type=application/json",
					"--set-env user-agent=GithubCopilot/1.155.0",
					"--set-env accept-encoding=gzip,deflate,br",
				},
				auto_reload = true,
				picker_cfg = {
					preset = "telescope",
				},
				config = {
					os = { editPreset = "nvim-remote" },
					gui = { nerdFontsVersion = "3" },
				},
				win = {
					wo = { winbar = "Aider" },
					style = "nvim_aider",
					position = "right",
				},
			})
		end,
	},
}
return M
