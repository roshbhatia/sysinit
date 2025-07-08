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
			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
			parser_config.gotmpl = {
				install_info = {
					url = "https://github.com/ngalaiko/tree-sitter-go-template",
					files = { "src/parser.c" },
				},
				filetype = "gotmpl",
				used_by = { "gohtmltmpl", "gotexttmpl", "gotmpl", "yaml" },
			}

			require("nvim-treesitter.configs").setup(opts)

			local query_sets = {
				yaml = {
					injections = [[
					((block_scalar) @injection.content
						(#contains? @injection.content "{{")
						(#set! injection.language "gotmpl"))

					((plain_scalar) @injection.content
						(#contains? @injection.content "{{")
						(#set! injection.language "gotmpl"))
					]],
					highlights = [[
					(block_mapping_pair
						key: (flow_node (plain_scalar) @keyword)
						value: (flow_node (plain_scalar) @string))

					((block_scalar) @string
						(#contains? @string "{{"))

					((plain_scalar) @string
						(#contains? @string "{{"))
					]],
				},
			}

			for lang, sets in pairs(query_sets) do
				for group, content in pairs(sets) do
					vim.treesitter.query.set(lang, group, content)
				end
			end
		end,
	},
}

return M
