local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("typescript", {
  -- Arrow function
  s(
    "af",
    fmt(
      [[
const {} = ({}) => {{
  {}
}}
]],
      {
        i(1, "funcName"),
        i(2, "params"),
        i(0),
      }
    )
  ),

  -- Async arrow function
  s(
    "afa",
    fmt(
      [[
const {} = async ({}) => {{
  {}
}}
]],
      {
        i(1, "funcName"),
        i(2, "params"),
        i(0),
      }
    )
  ),

  -- Interface
  s(
    "interface",
    fmt(
      [[
interface {} {{
  {}
}}
]],
      {
        i(1, "Name"),
        i(0),
      }
    )
  ),

  -- Type alias
  s(
    "type",
    fmt(
      [[
type {} = {}
]],
      {
        i(1, "Name"),
        i(2, "string"),
      }
    )
  ),

  -- Try-catch
  s(
    "try",
    fmt(
      [[
try {{
  {}
}} catch (error) {{
  console.error({}, error)
  {}
}}
]],
      {
        i(1, "// code"),
        i(2, '"Error:"'),
        i(0),
      }
    )
  ),

  -- Promise
  s(
    "promise",
    fmt(
      [[
new Promise<{}>(resolve, reject) => {{
  {}
}})
]],
      {
        i(1, "void"),
        i(0),
      }
    )
  ),

  -- Import
  s(
    "imp",
    fmt(
      [[
import {{ {} }} from "{}"
]],
      {
        i(1, "module"),
        i(2, "./module"),
      }
    )
  ),

  -- Export
  s(
    "exp",
    fmt(
      [[
export const {} = {}
]],
      {
        i(1, "name"),
        i(2, "value"),
      }
    )
  ),
})

-- Also add for TSX/React
ls.add_snippets("typescriptreact", {
  -- React functional component
  s(
    "rfc",
    fmt(
      [[
import React from "react"

interface {}Props {{
  {}
}}

export const {}: React.FC<{}Props> = ({{ {} }}) => {{
  return (
    <div>
      {}
    </div>
  )
}}
]],
      {
        i(1, "Component"),
        i(2, "// props"),
        i(3, "Component"),
        i(4, "Component"),
        i(5, "// destructured props"),
        i(0),
      }
    )
  ),

  -- useState hook
  s(
    "us",
    fmt(
      [[
const [{}, set{}] = React.useState{}({})
]],
      {
        i(1, "state"),
        i(2, "State"),
        i(3, "<Type>"),
        i(4, "initialValue"),
      }
    )
  ),

  -- useEffect hook
  s(
    "ue",
    fmt(
      [[
React.useEffect(() => {{
  {}
}}, [{}])
]],
      {
        i(1, "// effect"),
        i(2, "// dependencies"),
      }
    )
  ),

  -- useCallback hook
  s(
    "ucb",
    fmt(
      [[
const {} = React.useCallback(() => {{
  {}
}}, [{}])
]],
      {
        i(1, "callback"),
        i(2, "// callback body"),
        i(3, "// dependencies"),
      }
    )
  ),

  -- useMemo hook
  s(
    "um",
    fmt(
      [[
const {} = React.useMemo(() => {{
  return {}
}}, [{}])
]],
      {
        i(1, "memoized"),
        i(2, "value"),
        i(3, "// dependencies"),
      }
    )
  ),
})
