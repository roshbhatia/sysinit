local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

-- Clear existing snippets for "gotmpl" (or "yaml" if using Helm)
-- require("luasnip.session.snippet_collection").clear_snippets("gotmpl")

ls.add_snippets("gotmpl", {
  -- Basic Template Variable/Function
  s("vv", fmt("{{{{ {} }}}}{}", { i(1), i(0) })),

  -- String Functions
  s("trim", fmt("{{{{ trim {} }}}}{}", { i(1, '"string"'), i(0) })),
  s("trimAll", fmt("{{{{ trimAll {} {} }}}}{}", { i(1, '"$"'), i(2, '".00"'), i(0) })),
  s("upper", fmt("{{{{ upper {} }}}}{}", { i(1, '"hello"'), i(0) })),
  s("lower", fmt("{{{{ lower {} }}}}{}", { i(1, '"HELLO"'), i(0) })),
  s("title", fmt("{{{{ title {} }}}}{}", { i(1, '"hello world"'), i(0) })),
  s("repeat", fmt("{{{{ repeat {} {} }}}}{}", { i(1, "3"), i(2, '"hello"'), i(0) })),
  s("substr", fmt("{{{{ substr {} {} {} }}}}{}", { i(1, "0"), i(2, "5"), i(3, '"hello world"'), i(0) })),
  s("trunc", fmt("{{{{ trunc {} {} }}}}{}", { i(1, "5"), i(2, '"hello world"'), i(0) })),
  s("abbrev", fmt("{{{{ abbrev {} {} }}}}{}", { i(1, "5"), i(2, '"hello world"'), i(0) })),

  -- Indentation (Crucial for Helm/YAML)
  s("indent", fmt("{{{{ indent {} {} }}}}{}", { i(1, "4"), i(2, "$text"), i(0) })),
  s("nindent", fmt("{{{{ nindent {} {} }}}}{}", { i(1, "4"), i(2, "$text"), i(0) })),

  -- Logic / Control Flow
  s("contains", fmt("{{{{ if contains {} {} }}}}\n{}\n{{{{ end }}}}", { i(1, '"substr"'), i(2, '"str"'), i(0) })),
  s("replace", fmt("{{{{ {} | replace {} {} }}}}{}", { i(1, ".Var"), i(2, '"old"'), i(3, '"new"'), i(0) })),

  -- Randomization
  s("randAlphaNum", fmt("{{{{ randAlphaNum {} }}}}{}", { i(1, "10"), i(0) })),

  -- Regex
  s("regexMatch", fmt("{{{{ regexMatch {} {} }}}}{}", { i(1, '"^pattern$"'), i(2, '"input"'), i(0) })),
})
