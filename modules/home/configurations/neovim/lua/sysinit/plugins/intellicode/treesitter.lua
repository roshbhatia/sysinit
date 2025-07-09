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
				used_by = { "gohtmltmpl", "gotexttmpl", "gotmpl" },
			}
			require("nvim-treesitter.configs").setup(opts)

			local query_sets = {
				yaml = {
					injections = [[
			; Only inject gotmpl in Crossplane Compositions
			; Check for Composition kind and function-go-templating context
			(document
				(block_node
					(block_mapping
						(block_mapping_pair
							key: (flow_node (plain_scalar) @_kind_key)
							value: (flow_node (plain_scalar) @_kind_value))
						(block_mapping_pair
							key: (flow_node (plain_scalar) @_spec_key)
							value: (block_node
								(block_mapping
									(block_mapping_pair
										key: (flow_node (plain_scalar) @_pipeline_key)
										value: (block_node
											(block_sequence
												(block_sequence_item
													(block_node
														(block_mapping
															(block_mapping_pair
																key: (flow_node (plain_scalar) @_input_key)
																value: (block_node
																	(block_mapping
																		(block_mapping_pair
																			key: (flow_node (plain_scalar) @_template_key)
																			value: (block_node (block_scalar) @injection.content)))))))))))))
				(#eq? @_kind_key "kind")
				(#eq? @_kind_value "Composition")
				(#eq? @_spec_key "spec")
				(#eq? @_pipeline_key "pipeline")
				(#eq? @_input_key "input")
				(#eq? @_template_key "template")
				(#contains? @injection.content "{{")
				(#set! injection.language "gotmpl"))

			; Handle inline templates in function-go-templating inputs
			(document
				(block_node
					(block_mapping
						(block_mapping_pair
							key: (flow_node (plain_scalar) @_kind_key)
							value: (flow_node (plain_scalar) @_kind_value))
						(block_mapping_pair
							key: (flow_node (plain_scalar) @_api_key)
							value: (flow_node (plain_scalar) @_api_value))
						(block_mapping_pair
							key: (flow_node (plain_scalar) @_template_key)
							value: (block_node (block_scalar) @injection.content))))
				(#eq? @_kind_key "kind")
				(#eq? @_kind_value "GoTemplate")
				(#eq? @_api_key "apiVersion")
				(#match? @_api_value "gotemplating\.fn\.crossplane\.io")
				(#eq? @_template_key "template")
				(#contains? @injection.content "{{")
				(#set! injection.language "gotmpl"))

			; Handle quoted template strings in Crossplane context
			(document
				(block_node
					(block_mapping
						(block_mapping_pair
							key: (flow_node (plain_scalar) @_kind_key)
							value: (flow_node (plain_scalar) @_kind_value))
						; Look for nested template field in Composition context
						(block_mapping_pair
							value: (block_node
								(block_mapping
									(block_mapping_pair
										(block_mapping_pair
											key: (flow_node (plain_scalar) @_template_key)
											value: (flow_node (double_quote_scalar) @injection.content))))))))
				(#eq? @_kind_key "kind")
				(#eq? @_kind_value "Composition")
				(#eq? @_template_key "template")
				(#contains? @injection.content "{{")
				(#set! injection.language "gotmpl"))

			; Fallback for any YAML with specific Crossplane function annotations
			((block_scalar) @injection.content
				(#lua-match? @injection.content "apiVersion:%s*gotemplating%.fn%.crossplane%.io")
				(#contains? @injection.content "{{")
				(#set! injection.language "gotmpl"))

			; Plain scalars in Crossplane function context
			((plain_scalar) @injection.content
				(#lua-match? @injection.content "apiVersion:%s*gotemplating%.fn%.crossplane%.io")
				(#contains? @injection.content "{{")
				(#set! injection.language "gotmpl"))
			]],

					highlights = [[
			; Highlight Crossplane-specific keys
			(block_mapping_pair
				key: (flow_node (plain_scalar) @keyword.crossplane)
				(#any-of? @keyword.crossplane "apiVersion" "kind" "spec" "pipeline" "functionRef" "input" "source" "inline" "template"))

			; Highlight Go template content in Crossplane context only
			(block_mapping_pair
				key: (flow_node (plain_scalar) @_template_key)
				value: (block_node (block_scalar) @string.template)
				(#eq? @_template_key "template")
				(#contains? @string.template "{{"))

			; Highlight function names in Crossplane context
			(block_mapping_pair
				key: (flow_node (plain_scalar) @_name_key)
				value: (flow_node (plain_scalar) @function.name)
				(#eq? @_name_key "name")
				(#eq? @function.name "function-go-templating"))

			; Highlight Crossplane API versions
			(block_mapping_pair
				key: (flow_node (plain_scalar) @_api_key)
				value: (flow_node (plain_scalar) @constant.api)
				(#eq? @_api_key "apiVersion")
				(#any-of? @constant.api "apiextensions.crossplane.io/v1" "gotemplating.fn.crossplane.io/v1beta1"))

			; Highlight Crossplane kinds
			(block_mapping_pair
				key: (flow_node (plain_scalar) @_kind_key)
				value: (flow_node (plain_scalar) @type.crossplane)
				(#eq? @_kind_key "kind")
				(#any-of? @type.crossplane "Composition" "GoTemplate" "ExtraResources" "Context" "CompositeConnectionDetails" "ClaimConditions"))
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

