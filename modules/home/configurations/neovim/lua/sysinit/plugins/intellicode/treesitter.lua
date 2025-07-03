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
					 ((block_mapping_pair
					   key: (flow_node (plain_scalar) @_template_key (#eq? @_template_key "template"))
					   value: (flow_node (block_scalar) @injection.content))
					   (#set! injection.language "yaml")
					   (#set! injection.combined)
					   (#set! injection.include-children))

					 ((block_scalar) @injection.content
					   (#contains? @injection.content "{{")
					   (#not-contains? @injection.content "apiVersion")
					   (#set! injection.language "gotmpl")
					   (#set! injection.include-children))

					 ((plain_scalar) @injection.content
					   (#contains? @injection.content "{{")
					   (#contains? @injection.content "apiVersion")
					   (#set! injection.language "yaml")
					   (#set! injection.combined)
					   (#set! injection.include-children))
				   ]],
					highlights = [[
					 (block_mapping_pair
					   key: (flow_node (plain_scalar) @keyword (#eq? @keyword "apiVersion"))
					   value: (flow_node (plain_scalar) @type))

					 (block_mapping_pair
					   key: (flow_node (plain_scalar) @keyword (#eq? @keyword "kind"))
					   value: (flow_node (plain_scalar) @type.builtin))

					 (block_mapping_pair
					   key: (flow_node (plain_scalar) @keyword (#eq? @keyword "name"))
					   value: (flow_node (plain_scalar) @string))

					 (block_mapping_pair
					   key: (flow_node (plain_scalar) @keyword (#eq? @keyword "functionRef"))
					   value: (block_mapping (block_mapping_pair
					     key: (flow_node (plain_scalar) @keyword (#eq? @keyword "name"))
					     value: (flow_node (plain_scalar) @function))))

					 (block_scalar) @go_template
					   (#contains? @go_template "{{"))
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

