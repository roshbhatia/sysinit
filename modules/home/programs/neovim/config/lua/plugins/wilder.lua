return {
  {
    "gelguy/wilder.nvim",
    event = "VeryLazy",
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
            debounce = 30,
          }),
          wilder.vim_search_pipeline({
            debounce = 50,
          })
        ),
      })

      -- winborder="rounded" is set globally; clear it for the duration of cmdline
      -- so wilder's own palette border="rounded" is the only border drawn.
      local augroup_wb = vim.api.nvim_create_augroup("WilderWinborder", { clear = true })
      vim.api.nvim_create_autocmd("CmdlineEnter", {
        group = augroup_wb,
        callback = function() vim.o.winborder = "" end,
      })
      vim.api.nvim_create_autocmd("CmdlineLeave", {
        group = augroup_wb,
        callback = function() vim.o.winborder = "rounded" end,
      })

      local popupmenu_renderer = wilder.popupmenu_renderer(wilder.popupmenu_palette_theme({
        border = "rounded",
        max_height = "60%",
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
          selected_accent = "WilderSelectedAccent",
          border = "FloatBorder",
          accent = "WilderAccent",
        },
        left = {
          -- 3-element chunk: wilder uses [1] for non-selected, [2] for selected.
          -- WilderPrefixHidden blends with the popup bg so > is invisible on
          -- non-selected rows; WilderPrefixSelected makes it visible.
          { "> ", "WilderPrefixHidden", "WilderPrefixSelected" },
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
          border = "FloatBorder",
          selected = "WilderSelected",
          accent = "WilderAccent",
        },
        separator = " · ",
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
