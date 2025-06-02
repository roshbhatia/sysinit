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
			window = {
				layout = "float", -- 'float' | 'vertical' | 'horizontal' | 'center'
				border = "rounded", -- 'none' | 'single' | 'double' | 'single' | 'shadow' | 'solid'
			},
		},
	},
}
return M
