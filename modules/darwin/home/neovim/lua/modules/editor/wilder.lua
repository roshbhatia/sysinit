-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/gelguy/wilder.nvim/refs/heads/master/doc/wilder.txt"
local M = {}

M.plugins = {
  {
    "gelguy/wilder.nvim",
    event = "CmdlineEnter",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local wilder = require("wilder")
      wilder.setup({ modes = { ":", "/", "?" } })

      -- Create the popupmenu renderer with palette theme
      local popupmenu_renderer = wilder.popupmenu_renderer(wilder.popupmenu_palette_theme({
        border = "rounded",
        empty_message = wilder.popupmenu_empty_message_with_spinner(),
        highlighter = wilder.basic_highlighter(),
        left = {
          " ",
          wilder.popupmenu_devicons(),
          wilder.popupmenu_buffer_flags({
            flags = " a + ",
            icons = { ["+"] = "", a = "", h = "" },
          }),
        },
        right = {
          " ",
          wilder.popupmenu_scrollbar(),
        },
        -- Palette specific settings
        max_height = "75%",
        min_height = 0,
        prompt_position = "top",
        reverse = false,
      }))

      -- Create the wildmenu renderer
      local wildmenu_renderer = wilder.wildmenu_renderer({
        highlighter = highlighters,
        separator = " · ",
        left = { " ", wilder.wildmenu_spinner(), " " },
        right = { " ", wilder.wildmenu_index() },
      })

      -- Set up renderer based on mode
      wilder.set_option(
        "renderer",
        wilder.renderer_mux({
          [":"] = popupmenu_renderer,
          ["/"] = wildmenu_renderer,
          substitute = wildmenu_renderer,
        })
      )
    end,
  },
}

return M

