local M = {}
local config_path = vim.fn.stdpath("config")

M.plugins = {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		branch = "master",
		lazy = false,
		opts = {
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "gnn",
					node_incremental = "grn",
					scope_incremental = "grc",
					node_decremental = "grm",
				},
			},
			highlight = {
				enable = true,
			},
			sync_install = true,
			ensure_installed = {
				"bash",
				"c",
				"comment",
				"css",
				"csv",
				"cue",
				"diff",
				"dockerfile",
				"git_config",
				"git_rebase",
				"gitattributes",
				"gitcommit",
				"gitignore",
				"go",
				"gomod",
				"gosum",
				"gotmpl",
				"gowork",
				"hcl",
				"helm",
				"html",
				"java",
				"javascript",
				"jinja",
				"jinja_inline",
				"jq",
				"jsdoc",
				"json",
				"jsonc",
				"lua",
				"luadoc",
				"luap",
				"markdown",
				"markdown_inline",
				"nix",
				"python",
				"query",
				"regex",
				"ruby",
				"rust",
				"scss",
				"terraform",
				"toml",
				"tsv",
				"typescript",
				"vim",
				"vimdoc",
				"xml",
				"yaml",
			},
		},
		config = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, { "yaml", "go" })

			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
			parser_config.gotmpl = {
				install_info = {
					url = "https://github.com/ngalaiko/tree-sitter-go-template",
					files = { "src/parser.c" },
				},
				filetype = "gotmpl",
				used_by = { "gohtmltmpl", "gotexttmpl", "gotmpl" },
			}

			require("nvim-treesitter.configs").setup(opts)

			local function is_crossplane_file()
				local lines = vim.api.nvim_buf_get_lines(0, 0, 50, false)
				local content = table.concat(lines, "\n")
				local crossplane_patterns = {
					"kind:%s*Composition",
					"apiVersion:%s*apiextensions%.crossplane%.io",
					"gotemplating%.fn%.crossplane%.io",
					"function%-go%-templating",
					"functionRef:",
				}

				for _, pattern in ipairs(crossplane_patterns) do
					if content:match(pattern) then
						return true
					end
				end
				return false
			end

			local has_yaml = pcall(vim.treesitter.get_parser, 0, "yaml")
			local has_gotmpl = pcall(vim.treesitter.get_parser, 0, "gotmpl")

			if not (has_yaml and has_gotmpl) then
				return
			end

			local injection_query = [[
		; Only inject in template fields that contain Go template syntax
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_key)
			value: (block_node (block_scalar) @injection.content)
			(#eq? @_key "template")
			(#lua-match? @injection.content "%{%{.*%}%}")
			(#set! injection.language "gotmpl"))

		; Handle quoted strings with templates
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_key)
			value: (flow_node (double_quote_scalar) @injection.content)
			(#eq? @_key "template")
			(#lua-match? @injection.content "%{%{.*%}%}")
			(#set! injection.language "gotmpl"))
		]]

			local highlight_query = [[
		; Highlight template content
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_key)
			value: (block_node (block_scalar) @string.template)
			(#eq? @_key "template")
			(#lua-match? @string.template "%{%{.*%}%}"))
		]]

			local group = vim.api.nvim_create_augroup("CrossplaneTreesitter", { clear = true })
			vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
				group = group,
				pattern = "*.yaml",
				callback = function()
					if is_crossplane_file() then
						vim.treesitter.query.set("yaml", "injections", injection_query)
						vim.treesitter.query.set("yaml", "highlights", highlight_query)
					end
				end,
			})
		end,
	},
}

return M

