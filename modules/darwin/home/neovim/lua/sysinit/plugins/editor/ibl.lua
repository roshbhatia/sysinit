-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/lukas-reineke/indent-blankline.nvim/refs/heads/master/doc/indent_blankline.txt"
local M = {}

M.plugins = {
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		lazy = true,
		config = function()
			local ibl = require("ibl")
			local hooks = require("ibl.hooks")

			ibl.setup({
				enabled = true,
				debounce = 200,

				indent = {
					char = "▏",
					tab_char = "▏",
					highlight = "IblIndent",
					smart_indent_cap = true,
					priority = 1,
				},

				whitespace = {
					highlight = "IblWhitespace",
					remove_blankline_trail = true,
				},

				scope = {
					enabled = true,
					char = "▏",
					show_start = true,
					show_end = true,
					show_exact_scope = false,
					injected_languages = true,
					highlight = "IblScope",
					priority = 1024,
				},

				exclude = {
					filetypes = {
						"lspinfo",
						"packer",
						"checkhealth",
						"help",
						"man",
						"gitcommit",
						"TelescopePrompt",
						"TelescopeResults",
						"dashboard",
						"NeoTree",
						"lazy",
						"alpha",
						"oil",
						"Outline",
						"",
					},
					buftypes = { "terminal", "nofile", "quickfix", "prompt" },
				},
			})

			hooks.register(hooks.type.SKIP_LINE, hooks.builtin.skip_preproc_lines)
		end,
	},
}

return M
