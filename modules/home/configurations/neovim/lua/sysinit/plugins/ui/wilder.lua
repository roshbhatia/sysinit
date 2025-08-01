local M = {}

local function get_accent_color()
  local hl = vim.api.nvim_get_hl(0, { name = "@variable", link = false })
  return hl and hl.fg and string.format("#%06x", hl.fg) or "#f38ba8"
end

M.plugins = {
  {
    "gelguy/wilder.nvim",
    event = "CmdlineEnter",
    dependencies = {
      "romgrk/fzy-lua-native",
      "kyazdani42/nvim-web-devicons",
    },
    build = ":UpdateRemotePlugins",
    config = function()
      local wilder = require("wilder")
      wilder.setup({
        modes = { ":", "?" },
        next_key = "<Tab>",
        previous_key = "<S-Tab>",
        accept_key = "<CR>",
        reject_key = "<Esc>",
      })

      wilder.set_option("use_python_remote_plugin", 0)

      wilder.set_option("pipeline", {
        wilder.branch(
          {
            wilder.check(function(_, x)
              return vim.fn.empty(x)
            end),
            wilder.history(15),
          },
          wilder.cmdline_pipeline({
            fuzzy = 2,
            fuzzy_filter = wilder.lua_fzy_filter(),
          }),
          wilder.vim_search_pipeline()
        ),
      })
      local popupmenu_renderer = wilder.popupmenu_renderer(wilder.popupmenu_palette_theme({
        border = "rounded",
        highlighter = {
          wilder.lua_pcre2_highlighter(),
          wilder.lua_fzy_highlighter(),
        },
        highlights = {
          accent = wilder.make_hl("WilderAccent", "Pmenu", {
            {
              a = 1,
            },
            {
              a = 1,
            },
            {
              foreground = get_accent_color(),
            },
          }),
        },
        left = {
          " ",
          wilder.popupmenu_devicons(),
        },
        right = {
          " ",
          wilder.popupmenu_scrollbar(),
        },
      }))

      local wildmenu_renderer = wilder.wildmenu_renderer({
        separator = " · ",
        left = { " ", wilder.wildmenu_spinner(), " " },
        right = { " ", wilder.wildmenu_index() },
      })

      wilder.set_option(
        "renderer",
        wilder.renderer_mux({
          [":"] = popupmenu_renderer,
          ["/"] = wildmenu_renderer,
          substitute = wildmenu_renderer,
        })
      )

      vim.opt.wildignorecase = true
    end,
  },
}

return M
