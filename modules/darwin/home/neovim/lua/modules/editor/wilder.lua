-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/gelguy/wilder.nvim/refs/heads/master/doc/wilder.txt"
local M = {}

M.plugins = {
  {
    "gelguy/wilder.nvim",
    event = "CmdlineEnter",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "romgrk/fzy-lua-native",
      "nixprime/cpsm",
      "roxma/nvim-yarp",
      "roxma/vim-hug-neovim-rpc",
    },
    config = function()
      local wilder = require("wilder")
      wilder.setup({ modes = { ":", "/", "?" } })

      -- Advanced pipeline configuration
      wilder.set_option("pipeline", {
        wilder.branch(
          wilder.cmdline_pipeline({
            fuzzy = 1,
            fuzzy_filter = wilder.lua_fzy_filter(),
          }),
          wilder.vim_search_pipeline()
        ),
      })

      -- Highlighters configuration
      local highlighters = {
        wilder.pcre2_highlighter(),
        wilder.lua_fzy_highlighter(),
      }

      -- Create the popupmenu renderer with palette theme
      local popupmenu_renderer = wilder.popupmenu_renderer(wilder.popupmenu_palette_theme({
        border = "rounded",
        empty_message = wilder.popupmenu_empty_message_with_spinner(),
        highlighter = highlighters,
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

      -- Register with which-key
      local wk = require("which-key")
      wk.add({
        { "<leader>:", ":", desc = "Command-line (Wilder)", mode = "n" },
      })
    end,
  },
}

return M

