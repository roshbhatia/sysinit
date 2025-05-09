local M = {}

M.plugins = {
	{

		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "canary",
		dependencies = {
			{ "zbirenbaum/copilot.lua" },
			{ "nvim-lua/plenary.nvim" },
		},
		cmd = {
			"CopilotChat",
			"CopilotChatOpen",
			"CopilotChatToggle",
			"CopilotChatExplain",
			"CopilotChatTests",
			"CopilotChatFix",
			"CopilotChatOptimize",
			"CopilotChatDocs",
		},
		keys = function()
			return {
				{
					"<leader>ae",
					"<cmd>CopilotChatExplain<cr>",
					desc = "AI: Explain code",
				},
				{
					"<leader>at",
					"<cmd>CopilotChatTests<cr>",
					desc = "AI: Generate tests",
				},
				{
					"<leader>af",
					"<cmd>CopilotChatFix<cr>",
					desc = "AI: Fix code",
				},
				{
					"<leader>ao",
					"<cmd>CopilotChatOptimize<cr>",
					desc = "AI: Optimize code",
				},
				{
					"<leader>ad",
					"<cmd>CopilotChatDocs<cr>",
					desc = "AI: Generate docs",
				},
			}
		end,
		opts = {
			debug = false,
			prompts = {
				Explain = {
					prompt = "Explain how this code works in detail.",
				},
				Tests = {
					prompt = "Generate unit tests for this code.",
				},
				Fix = {
					prompt = "Fix this code to resolve errors and improve error handling.",
				},
				Optimize = {
					prompt = "Optimize this code for better performance and readability.",
				},
				Docs = {
					prompt = "Generate detailed documentation for this code.",
				},
			},
			mappings = {
				close = {
					normal = "q",
					insert = "<C-c>",
				},
				reset = {
					normal = "<C-l>",
					insert = "<C-l>",
				},
				complete = {
					normal = "<Tab>",
					insert = "<Tab>",
				},
				submit_prompt = {
					normal = "<CR>",
					insert = "<C-CR>",
				},
				accept_diff = {
					normal = "<C-y>",
					insert = "<C-y>",
				},
				show_diff = {
					normal = "gd",
				},
				show_system_prompt = {
					normal = "gp",
				},
				show_user_selection = {
					normal = "gs",
				},
			},
			question_sign = "?",
			answer_sign = "!",
			error_sign = "!",
			window = {
				layout = "float", -- 'float' | 'vertical' | 'horizontal' | 'center'
				relative = "cursor", -- 'cursor' | 'editor'
				border = "rounded", -- 'none' | 'single' | 'double' | 'single' | 'shadow' | 'solid'
				width = 0.8, -- fractional width of parent
				height = 0.6, -- fractional height of parent
				row = nil, -- row position of the window, default is centered
				col = nil, -- column position of the window, default is centered
				title = "Copilot Chat", -- title of chat window
				footer = nil, -- footer of chat window
				zindex = 1, -- determines if window is on top or bottom
			},
			system_prompt = [[
                You are an AI programming assistant, knowledgeable about all programming languages, frameworks, and tools.
                
                - When asked to explain code, analyze it in detail, including architectural patterns, potential bugs, and performance considerations. 
                - When asked to optimize code, focus on readability, performance, and best practices.
                - When asked to generate tests, create comprehensive unit tests that cover edge cases.
                - When asked to fix code, identify and resolve errors, add proper error handling, and improve robustness.
                - When asked to document code, produce clear, concise documentation that explains purpose, parameters, returns, and examples.
                
                You speak technically and use programming idioms. Keep explanations concise but complete, including context when helpful.
            ]],
		},
		config = function(_, opts)
			require("CopilotChat").setup(opts)

			-- Create custom command aliases for easy access
			vim.api.nvim_create_user_command("CC", "CopilotChat", {})
			vim.api.nvim_create_user_command("CCE", "CopilotChatExplain", {})
			vim.api.nvim_create_user_command("CCT", "CopilotChatTests", {})
			vim.api.nvim_create_user_command("CCF", "CopilotChatFix", {})
			vim.api.nvim_create_user_command("CCO", "CopilotChatOptimize", {})
			vim.api.nvim_create_user_command("CCD", "CopilotChatDocs", {})
		end,
	},
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		version = false,
		opts = {
			provider = "copilot:3.7",
			auto_suggestions_provider = "copilot:3.7",
			vendors = {
				["copilot:3.7"] = {
					__inherited_from = "copilot",
					model = "claude-3.7-sonnet",
					disabled_tools = { "web_search" },
					max_tokens = 16384,
				},
				["copilot:3.5"] = {
					__inherited_from = "copilot",
					model = "claude-3.5-sonnet",
					disabled_tools = { "web_search" },
					max_tokens = 16384,
				},
				["copilot:o3"] = {
					__inherited_from = "copilot",
					model = "o3-mini",
					disabled_tools = { "web_search" },
					max_tokens = 16384,
				},
			},
			behaviour = {
				auto_suggestions = false,
				auto_set_keymaps = false,
			},
		},
		build = ":AvanteBuild",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-telescope/telescope.nvim",
			"hrsh7th/nvim-cmp",
			"nvim-tree/nvim-web-devicons",
			"zbirenbaum/copilot.lua",
			"MeanderingProgrammer/render-markdown.nvim",
		},
		keys = function()
			return {
				{
					"<leader>aa",
					"<cmd>AvanteToggle<cr>",
					desc = "AI: Toggle chat",
				},
				{
					"<leader>ac",
					"<cmd>AvanteClear<cr>",
					desc = "AI: Clear chat",
				},
				{
					"<leader>ah",
					"<cmd>AvanteHistory<cr>",
					desc = "AI: Chat history",
				},
				{
					"<leader>as",
					"<cmd>AvanteStop<cr>",
					desc = "AI: Stop current request",
				},
				{
					"<leader>an",
					"<cmd>AvanteChatNew<cr>",
					desc = "AI: New chat",
				},
			}
		end,
	},
}
return M
