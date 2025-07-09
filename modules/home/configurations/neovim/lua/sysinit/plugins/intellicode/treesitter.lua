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

			local has_yaml = pcall(function()
				return vim.treesitter.language.add("yaml")
			end)
			local has_gotmpl = pcall(function()
				return vim.treesitter.language.add("gotmpl")
			end)

			if not (has_yaml and has_gotmpl) then
				vim.notify("YAML or GoTmpl parser not ready, skipping injection setup", vim.log.levels.DEBUG)
				return
			end

			local injection_query = [[
		; Inject gotmpl into template block scalars in Crossplane context
		(document
			(block_node
				(block_mapping
					(block_mapping_pair
						key: (flow_node (plain_scalar) @_kind_key)
						value: (flow_node (plain_scalar) @_kind_value))
					(block_mapping_pair
						key: (flow_node (plain_scalar) @_api_key)
						value: (flow_node (plain_scalar) @_api_value))))
			; Look for the template field in the same document
			(block_node
				(block_mapping
					(block_mapping_pair
						key: (flow_node (plain_scalar) @_template_key)
						value: (block_node (block_scalar) @injection.content))))
			(#eq? @_kind_key "kind")
			(#any-of? @_kind_value "Composition" "GoTemplate")
			(#eq? @_api_key "apiVersion")
			(#any-of? @_api_value "apiextensions.crossplane.io/v1" "gotemplating.fn.crossplane.io/v1beta1")
			(#eq? @_template_key "template")
			(#set! injection.language "gotmpl")
			(#set! injection.combined))

		; Alternative pattern - inject if we find template field with Go template syntax
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_key)
			value: (block_node (block_scalar) @injection.content)
			(#eq? @_key "template")
			(#lua-match? @injection.content "%{%{")
			(#set! injection.language "gotmpl")
			(#set! injection.combined))

		; Handle folded block scalars too (template: >)
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_key)
			value: (block_node (block_scalar) @injection.content)
			(#eq? @_key "template")
			(#lua-match? @injection.content "%{%{")
			(#set! injection.language "gotmpl")
			(#set! injection.combined))

		; Handle quoted template strings
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_key)
			value: (flow_node (double_quote_scalar) @injection.content)
			(#eq? @_key "template")
			(#lua-match? @injection.content "%{%{")
			(#set! injection.language "gotmpl")
			(#set! injection.combined))
		]]

			local highlight_query = [[
		; Highlight Crossplane-specific keywords
		(block_mapping_pair
			key: (flow_node (plain_scalar) @keyword.crossplane)
			(#any-of? @keyword.crossplane "apiVersion" "kind" "spec" "pipeline" "functionRef" "input" "source" "inline" "template" "compositeTypeRef" "mode"))

		; Highlight Crossplane API versions
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_api_key)
			value: (flow_node (plain_scalar) @constant.builtin.crossplane)
			(#eq? @_api_key "apiVersion")
			(#any-of? @constant.builtin.crossplane "apiextensions.crossplane.io/v1" "gotemplating.fn.crossplane.io/v1beta1" "example.crossplane.io/v1beta1"))

		; Highlight Crossplane kinds
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_kind_key)
			value: (flow_node (plain_scalar) @type.builtin.crossplane)
			(#eq? @_kind_key "kind")
			(#any-of? @type.builtin.crossplane "Composition" "GoTemplate" "XR" "CompositeConnectionDetails"))

		; Highlight function names
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_name_key)
			value: (flow_node (plain_scalar) @function.builtin)
			(#eq? @_name_key "name")
			(#eq? @function.builtin "function-go-templating"))

		; Highlight template content blocks
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_template_key)
			value: (block_node (block_scalar) @string.special.symbol)
			(#eq? @_template_key "template"))

		; Highlight step names
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_step_key)
			value: (flow_node (plain_scalar) @string.special)
			(#eq? @_step_key "step"))

		; Highlight source types
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_source_key)
			value: (flow_node (plain_scalar) @constant)
			(#eq? @_source_key "source")
			(#any-of? @constant "Inline" "FileSystem" "Environment"))

		; Highlight mode values
		(block_mapping_pair
			key: (flow_node (plain_scalar) @_mode_key)
			value: (flow_node (plain_scalar) @constant)
			(#eq? @_mode_key "mode")
			(#any-of? @constant "Pipeline" "Resources"))
		]]

			vim.treesitter.query.set("yaml", "injections", injection_query)
			vim.treesitter.query.set("yaml", "highlights", highlight_query)
		end,
	},
}

return M
