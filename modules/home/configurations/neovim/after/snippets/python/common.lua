local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("python", {
  -- Function definition
  s(
    "def",
    fmt(
      [[
def {}({}):
    """{}"""
    {}
]],
      {
        i(1, "function"),
        i(2, "args"),
        i(3, "Docstring"),
        i(0),
      }
    )
  ),

  -- Class definition
  s(
    "class",
    fmt(
      [[
class {}:
    """{}"""

    def __init__(self, {}):
        {}
]],
      {
        i(1, "ClassName"),
        i(2, "Docstring"),
        i(3, "args"),
        i(0),
      }
    )
  ),

  -- Try-except
  s(
    "try",
    fmt(
      [[
try:
    {}
except {} as e:
    {}
]],
      {
        i(1, "# code"),
        i(2, "Exception"),
        i(0, "print(e)"),
      }
    )
  ),

  -- With statement (context manager)
  s(
    "with",
    fmt(
      [[
with {} as {}:
    {}
]],
      {
        i(1, "expression"),
        i(2, "var"),
        i(0),
      }
    )
  ),

  -- If main
  s(
    "main",
    fmt(
      [[
if __name__ == "__main__":
    {}
]],
      {
        i(0),
      }
    )
  ),

  -- List comprehension
  s(
    "lc",
    fmt(
      [[
[{} for {} in {}]
]],
      {
        i(1, "x"),
        i(2, "x"),
        i(3, "iterable"),
      }
    )
  ),

  -- Dict comprehension
  s(
    "dc",
    fmt(
      [[
{{{}: {} for {} in {}}}
]],
      {
        i(1, "k"),
        i(2, "v"),
        i(3, "item"),
        i(4, "iterable"),
      }
    )
  ),

  -- Dataclass
  s(
    "dataclass",
    fmt(
      [[
@dataclass
class {}:
    {}: {}
]],
      {
        i(1, "ClassName"),
        i(2, "field"),
        i(3, "str"),
      }
    )
  ),

  -- Property
  s(
    "prop",
    fmt(
      [[
@property
def {}(self):
    return self._{}
]],
      {
        i(1, "property"),
        i(2, "property"),
      }
    )
  ),

  -- Async function
  s(
    "async",
    fmt(
      [[
async def {}({}):
    """{}"""
    {}
]],
      {
        i(1, "function"),
        i(2, "args"),
        i(3, "Docstring"),
        i(0),
      }
    )
  ),
})
