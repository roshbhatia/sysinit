local M = {}

M.plugins = {
	{
		enabled = false,
		"olimorris/codecompanion.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"ravitemer/mcphub.nvim",
		},
		config = function()
			require("codecompanion").setup({
				opts = {
					register = "+y",
				},
				extensions = {
					mcphub = {
						callback = "mcphub.extensions.codecompanion",
						opts = {
							make_vars = true,
							make_slash_commands = true,
							show_result_in_chat = true,
						},
					},
				},
				strategies = {
					chat = {
						tools = {
							opts = {
								auto_submit_errors = true,
								auto_submit_success = true,
							},
						},
						keymaps = {
							send = {
								modes = {
									n = "<S-CR>",
									i = "<S-CR>",
								},
							},
							stop = {
								modes = {
									n = "qq",
								},
								index = 5,
								callback = "keymaps.stop",
								description = "Stop Request",
							},
							clear = {
								modes = {
									n = "qx",
								},
								index = 6,
								callback = "keymaps.clear",
								description = "Clear Chat",
							},
							codeblock = {
								modes = {
									n = "qc",
								},
								index = 7,
								callback = "keymaps.codeblock",
								description = "Insert Codeblock",
							},
							yank_code = {
								modes = {
									n = "qy",
									v = "qy",
								},
								index = 8,
								callback = "keymaps.yank_code",
								description = "Yank Code",
							},
							pin = {
								modes = {
									n = "qp",
								},
								index = 9,
								callback = "keymaps.pin_reference",
								description = "Pin Reference",
							},
							watch = {
								modes = {
									n = "qw",
								},
								index = 10,
								callback = "keymaps.toggle_watch",
								description = "Watch Buffer",
							},
						},
						opts = {
							system_prompt = function(opts)
								return [[You are an AI programming assistant named "CodeCompanion". You are currently plugged in to the Neovim text editor on a user's machine.
Your core tasks include:
- Answering general programming questions.
- Explaining how the code in a Neovim buffer works.
- Reviewing the selected code in a Neovim buffer.
- Generating unit tests for the selected code.
- Proposing fixes for problems in the selected code.
- Scaffolding code for a new workspace.
- Finding relevant code to the user's query.
- Proposing fixes for test failures.
- Answering questions about Neovim.
- Running tools.

You MUST:
- Follow the user's requirements carefully and to the letter.
- Keep your answers short and impersonal, especially if the user responds with context outside of your tasks.
- Minimize other prose.
- Use Markdown formatting in your answers.
- Include the programming language name at the start of the Markdown code blocks.
- AVOID including line numbers in code blocks.
- AVOID wrapping the whole response in triple backticks.
- Only return code that's relevant to the task at hand. You may NOT need to return all of the code that the user has shared.
- Use actual line breaks instead of '\n' in your response to begin new lines.
- Use '\n' only when you want a literal backslash followed by a character 'n'.
- All non-code responses MUST be in %s.

When given a task:
1. You MUST step-by-step using the sequential-thinking tool and describe your plan for what to build in pseudocode, written out in great detail, UNLESS asked NOT to do so.
2. You MUST the code in a single code block, being careful to only return relevant code. DO NOT comment the code unless asked to do so explicitly.
3. You SHOULD always generate short suggestions for the next user turns that are relevant to the conversation.
4. You CAN only give one reply for each conversation turn.

You MUST use the following MCP tools:
- sequential-thinking: Dynamic, reflective problem-solving. Break down complex problems, branch reasoning, generate and verify hypotheses.
- memory: Save and retrieve state, update knowledge graph with new facts, entities, and relationships.
- context7: Fetch up-to-date, version-specific documentation and code examples directly into your prompt.

For memory usage, follow these steps for each interaction:
1. Assume you are interacting with default_user. If NOT identified, proactively try to do so.
2. You MUST always begin your chat by saying only "Remembering..." and retrieve all relevant information from your knowledge graph ("memory").
3. While conversing, you MUST be attentive to new information about identity, behaviors, preferences, goals, and relationships.
4. If new information is gathered, you MUST update your memory: create entities, connect them, and store facts as observations.
]]
							end,
							prompt_decorator = function(message, adapter, context)
								return string.format([[<prompt>%s</prompt>]], message)
							end,
						},
					},
				},
				display = {
					action_palette = {
						provider = "telescope",
					},
					chat = {
						show_header_seperator = true,
						show_references = true,
						icons = {
							pinned_buffer = " ",
							watched_buffer = "󱣽 ",
						},
						window = {
							position = "right",
							opts = {
								cursorline = false,
							},
						},
					},
				},
			})
		end,
		keys = {
			{
				"<leader>aa",
				"<cmd>CodeCompanionChat Toggle<cr>",
				desc = "CodeCompanion: Toggle Chat",
			},
			{
				"<leader>ai",
				"<cmd>CodeCompanion<cr>",
				desc = "CodeCompanion: Inline Assistant",
			},
			{
				"<leader>ac",
				"<cmd>CodeCompanionChat<cr>",
				desc = "CodeCompanion: Chat",
			},
			{
				"<leader>ad",
				"<cmd>CodeCompanionChat Add<cr>",
				desc = "CodeCompanion: Add Selection to Chat",
			},
			{
				"<leader>as",
				"<cmd>CodeCompanionActions<cr>",
				desc = "CodeCompanion: Actions",
			},
			{
				"<leader>am",
				"<cmd>CodeCompanionCmd<cr>",
				desc = "CodeCompanion: Command-line",
			},
		},
	},
}

return M
