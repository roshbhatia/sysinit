local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("lua", {
  s(
    "autocmd",
    fmt(
      [[
vim.api.nvim_create_autocmd({}, {{
  pattern = {},
  callback = function()
    {}
  end,
}})
]],
      {
        i(1, '"BufEnter"'),
        i(2, '"*"'),
        i(0),
      }
    )
  ),

  s(
    "augroup",
    fmt(
      [[
local augroup = vim.api.nvim_create_augroup("{}", {{ clear = true }})
vim.api.nvim_create_autocmd({}, {{
  group = augroup,
  pattern = {},
  callback = function()
    {}
  end,
}})
]],
      {
        i(1, "MyGroup"),
        i(2, '"BufEnter"'),
        i(3, '"*"'),
        i(0),
      }
    )
  ),

  s(
    "map",
    fmt(
      [[
vim.keymap.set({}, {}, {}, {{ desc = "{}" }})
]],
      {
        i(1, '"n"'),
        i(2, '"<leader>x"'),
        i(3, "function()"),
        i(4, "Description"),
      }
    )
  ),

  s(
    "mapb",
    fmt(
      [[
vim.keymap.set({}, {}, {}, {{ buffer = true, desc = "{}" }})
]],
      {
        i(1, '"n"'),
        i(2, '"<localleader>x"'),
        i(3, "function()"),
        i(4, "Description"),
      }
    )
  ),

  s(
    "cmd",
    fmt(
      [[
vim.api.nvim_create_user_command("{}", function(opts)
  {}
end, {{ nargs = {} }})
]],
      {
        i(1, "CommandName"),
        i(2, "-- command implementation"),
        i(3, "0"),
      }
    )
  ),

  s(
    "hl",
    fmt(
      [[
vim.api.nvim_set_hl(0, "{}", {{ fg = "{}", bg = "{}" }})
]],
      {
        i(1, "HighlightGroup"),
        i(2, "#ffffff"),
        i(3, "NONE"),
      }
    )
  ),

  s(
    "opt",
    fmt(
      [[
vim.opt.{} = {}
]],
      {
        i(1, "option"),
        i(2, "value"),
      }
    )
  ),

  s(
    "optl",
    fmt(
      [[
vim.opt_local.{} = {}
]],
      {
        i(1, "option"),
        i(2, "value"),
      }
    )
  ),

  s(
    "plugin",
    fmt(
      [[
{{
  "{}",
  config = function()
    require("{}").setup({{
      {}
    }})
  end,
}}
]],
      {
        i(1, "author/plugin"),
        i(2, "plugin"),
        i(0),
      }
    )
  ),

  s(
    "req",
    fmt(
      [[
local ok, {} = pcall(require, "{}")
if not ok then
  return
end
]],
      {
        i(1, "module"),
        i(2, "module"),
      }
    )
  ),
})
