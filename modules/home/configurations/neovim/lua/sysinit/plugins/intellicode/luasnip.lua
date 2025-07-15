local M = {}

M.plugins = {
	{
		"L3MON4D3/LuaSnip",
		lazy = true,
		version = "v2.*",
		build = "make install_jsregexp",
		dependencies = {
			"rafamadriz/friendly-snippets",
		},
		config = function()
			require("luasnip").filetype_extend("bash", { "shell" })
			require("luasnip").filetype_extend("go", {})
			require("luasnip").filetype_extend("javascript", { "jsdoc" })
			require("luasnip").filetype_extend("lua", { "luadoc" })
			require("luasnip").filetype_extend("make", { "make" })
			require("luasnip").filetype_extend("markdown", { "markdown" })
			require("luasnip").filetype_extend("python", { "pydoc" })
			require("luasnip").filetype_extend("rust", { "rustdoc" })
			require("luasnip").filetype_extend("sh", { "shelldoc" })
			require("luasnip").filetype_extend("typescript", { "tsdoc" })
			require("luasnip").filetype_extend("yaml", { "kubernetes" })
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},
}

return M
