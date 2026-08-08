local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("go", {
  s(
    "iferr",
    fmt(
      [[
if err != nil {{
	{}
}}
]],
      { i(1, "return err") }
    )
  ),

  s(
    "errf",
    fmt(
      [[
if err != nil {{
	return fmt.Errorf("{}: %w", {}, err)
}}
]],
      { i(1, "failed to do something"), i(2, "args") }
    )
  ),

  s(
    "test",
    fmt(
      [[
func Test{}(t *testing.T) {{
	{}
}}
]],
      { i(1, "Function"), i(0) }
    )
  ),

  s(
    "struct",
    fmt(
      [[
type {} struct {{
	{}
}}
]],
      { i(1, "Name"), i(0) }
    )
  ),

  s(
    "interface",
    fmt(
      [[
type {} interface {{
	{}
}}
]],
      { i(1, "Name"), i(0) }
    )
  ),

  s(
    "method",
    fmt(
      [[
func ({}  *{}) {}({}) {} {{
	{}
}}
]],
      { i(1, "r"), i(2, "Receiver"), i(3, "Method"), i(4, "args"), i(5, "error"), i(0) }
    )
  ),

  s(
    "handler",
    fmt(
      [[
func {}(w http.ResponseWriter, r *http.Request) {{
	{}
}}
]],
      { i(1, "Handler"), i(0) }
    )
  ),

  s(
    "go",
    fmt(
      [[
go func() {{
	{}
}}()
]],
      { i(0) }
    )
  ),

  s(
    "chan",
    fmt(
      [[
{} := make(chan {}{})
]],
      { i(1, "ch"), i(2, "type"), i(3, ", 0") }
    )
  ),

  s(
    "ctx",
    fmt(
      [[
ctx, cancel := context.WithTimeout(context.Background(), {})
defer cancel()
]],
      { i(1, "5*time.Second") }
    )
  ),
})
