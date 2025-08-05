local M = {}

local function get_accent_color()
  local hl = vim.api.nvim_get_hl(0, { name = "@variable", link = false })
  return hl and hl.fg and string.format("#%06x", hl.fg) or "#f38ba8"
end

local function get_gradient_colors()
  local accent = get_accent_color()
  return {
    accent,
    accent .. "dd",
    accent .. "bb",
    accent .. "99",
  }
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
        modes = { ":", "/", "?" },
        next_key = "<Tab>",
        previous_key = "<S-Tab>",
        accept_key = "<CR>",
        reject_key = "<Esc>",
        accept_completion_auto_select = true,
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
            debounce = 30,
          }),
          wilder.vim_search_pipeline({
            debounce = 50,
          })
        ),
      })

      local gradient_colors = get_gradient_colors()
      local gradient_hls = {}
      for i, color in ipairs(gradient_colors) do
        gradient_hls[i] = "WilderGradient" .. i
      end

      local popupmenu_renderer = wilder.popupmenu_renderer(wilder.popupmenu_palette_theme({
        border = "rounded",
        max_height = "50%",
        min_height = 0,
        prompt_position = "top",
        reverse = 0,

        highlighter = {
          wilder.lua_fzy_highlighter(),
        },

        highlights = {
          default = "Pmenu",
          selected = "PmenuSel",
          border = "FloatBorder",
          accent = "Special",
          selected_accent = "IncSearch",
          gradient = gradient_hls,
          selected_gradient = gradient_hls,
        },

        left = {
          " ",
          wilder.popupmenu_devicons({
            get_icon = function(ctx, file_name, is_dir)
              if is_dir then
                return " "
              end
              local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
              if devicons_ok then
                local icon, hl = devicons.get_icon(file_name, vim.fn.fnamemodify(file_name, ":e"))
                return icon or " "
              end
              return " "
            end,
            padding = { 0, 1 },
          }),
          {
            " ",
            wilder.make_hl("WilderSeparator", "Comment", {
              {},
              {},
              { foreground = "#6c7086" },
            }),
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
          spinner_hl = wilder.make_hl("WilderSpinner", "Comment"),
        }),
      }))

      local wildmenu_renderer = wilder.wildmenu_renderer({
        highlights = {
          default = "StatusLine",
          selected = "WildMenu",
          accent = wilder.make_hl("WilderWildmenuAccent", "StatusLine", {
            {},
            {},
            {
              foreground = get_accent_color(),
              bold = true,
            },
          }),
        },
        separator = " · ",
        left = {
          " ",
          wilder.wildmenu_spinner({
            frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
            done = "●",
            delay = 50,
            interval = 80,
          }),
          " ",
        },
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

      vim.opt.wildignorecase = true
      vim.opt.wildmenu = true
      vim.opt.wildmode = "longest:full,full"

      local wilder_group = vim.api.nvim_create_augroup("WilderColorUpdate", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = wilder_group,
        callback = function()
          vim.defer_fn(function()
            wilder.set_option("renderer", wilder.get_option("renderer"))
          end, 100)
        end,
      })
    end,
  },
}

return M

