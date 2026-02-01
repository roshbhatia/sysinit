return {
  "gelguy/wilder.nvim",
  event = "CmdlineEnter",
  dependencies = { "romgrk/fzy-lua-native" },
  build = ":UpdateRemotePlugins",
  config = function()
    local wilder = require("wilder")

    vim.opt.wildchar = 0
    vim.opt.wildcharm = 0
    vim.opt.wildmode = ""

    wilder.setup({
      modes = { ":", "/", "?" },
      next_key = "<Tab>",
      previous_key = "<S-Tab>",
      accept_key = "<CR>",
      reject_key = "<Esc>",
    })

    wilder.set_option("use_python_remote_plugin", 0)
    wilder.set_option("num_workers", 0)

    wilder.set_option("pipeline", {
      wilder.branch(
        wilder.cmdline_pipeline({
          fuzzy = 2,
          fuzzy_filter = wilder.lua_fzy_filter(),
          debounce = 30,
        }),
        wilder.vim_search_pipeline({ debounce = 50 })
      ),
    })

    wilder.set_option(
      "renderer",
      wilder.popupmenu_renderer(wilder.popupmenu_palette_theme({
        border = "rounded",
        max_height = "50%",
        min_height = 0,
        prompt_position = "top",
        reverse = 0,
        pumblend = 20,
        highlighter = wilder.lua_fzy_highlighter(),
        highlights = {
          default = "Pmenu",
          selected = "PmenuSel",
          border = "FloatBorder",
          accent = "WilderAccent",
        },
        left = { " ", wilder.popupmenu_devicons() },
        right = {
          " ",
          wilder.popupmenu_scrollbar({
            thumb_char = "█",
            scrollbar_char = "░",
          }),
        },
        empty_message = wilder.popupmenu_empty_message_with_spinner({
          message = " nothing found ",
          spinner_hl = "WilderSpinner",
        }),
      }))
    )
  end,
}
