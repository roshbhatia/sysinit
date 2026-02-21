return {
  {
    "gelguy/wilder.nvim",
    event = "CmdlineEnter",
    dependencies = {
      "romgrk/fzy-lua-native",
    },
    build = ":UpdateRemotePlugins",
    config = function()
      local wilder = require("wilder")

      wilder.setup({
        modes = { ":", "/", "?" },
        next_key = "<Tab>",
        previous_key = "<S-Tab>",
        accept_key = "<CR>",
        reject_key = "<Esc>",
        accept_completion_auto_select = false,
      })

      wilder.set_option("use_python_remote_plugin", 0)
      wilder.set_option("num_workers", 0)

      wilder.set_option("pipeline", {
        wilder.branch(
          {
            wilder.check(function(_, x)
              return vim.fn.empty(x)
            end),
            wilder.history(25),
          },
          wilder.cmdline_pipeline({
            language = "vim",
            fuzzy = 2,
            fuzzy_filter = wilder.lua_fzy_filter(),
            allow_fuzzy_deletion = true,
            debounce = 30,
          }),
          wilder.vim_search_pipeline({
            debounce = 50,
          })
        ),
      })

      local popupmenu_renderer = wilder.popupmenu_renderer(wilder.popupmenu_palette_theme({
        border = "rounded",
        max_height = "50%",
        min_height = 0,
        prompt_position = "top",
        reverse = 0,
        pumblend = 0,
        highlighter = {
          wilder.lua_fzy_highlighter(),
        },
        highlights = {
          default = "Pmenu",
          selected = "WilderSelected",
          border = "FloatBorder",
          accent = "WilderAccent",
        },
        left = {
          " ",
          {
            " ",
            "WilderSeparator",
          },
        },
        right = {
          " ",
          wilder.popupmenu_scrollbar({
            thumb_char = "█",
            scrollbar_char = "░",
          }),
        },
        empty_message = wilder.popupmenu_empty_message_with_spinner({
          message = " No matches found ",
          spinner_hl = "WilderSpinner",
        }),
      }))

      local wildmenu_renderer = wilder.wildmenu_renderer({
        highlights = {
          default = "Pmenu",
          selected = "WilderWildmenuSelected",
          accent = "WilderAccent",
        },
        separator = " · ",
        right = {
          " ",
          wilder.wildmenu_index(),
          " ",
        },
        highlighter = {
          wilder.lua_fzy_highlighter(),
        },
      })

      wilder.set_option(
        "renderer",
        wilder.renderer_mux({
          [":"] = popupmenu_renderer,
          ["/"] = wildmenu_renderer,
          ["?"] = wildmenu_renderer,
          substitute = wildmenu_renderer,
        })
      )
    end,
  },
}
