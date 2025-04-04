-- Keystroke display configuration
local M = {}

function M.setup()
  -- Check if we can load the noice plugin
  local has_noice, noice = pcall(require, "noice")
  if not has_noice then
    return
  end
  
  -- Configure noice for keystroke display
  noice.setup({
    cmdline = {
      enabled = true,
      view = "cmdline",
      format = {
        cmdline = { icon = "❯", title = "Command" },
        search_down = { icon = "🔍⌄", title = "Search" },
        search_up = { icon = "🔍⌃", title = "Search" },
        filter = { icon = "$", title = "Filter" },
        lua = { icon = "☾", title = "Lua" },
        help = { icon = "?", title = "Help" },
      },
    },
    messages = {
      enabled = true,
      view = "mini",
      view_warn = "mini",
      view_error = "mini",
      view_history = "messages",
    },
    views = {
      mini = {
        win_options = {
          winblend = 0,
        },
      },
      cmdline_popup = {
        border = {
          style = "rounded",
          padding = { 0, 1 },
        },
        filter_options = {},
        win_options = {
          winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
        },
      },
    },
    routes = {
      -- Show macro recording messages in the cmdline area
      {
        filter = {
          event = "msg_showmode",
        },
        view = "cmdline",
      },
      -- Hide written messages
      {
        filter = {
          event = "msg_show",
          kind = "",
          find = "written",
        },
        opts = { skip = true },
      },
    },
    -- Show key presses
    notify = {
      enabled = true,
      view = "mini",
    },
    -- Show keys in command line
    keystrokes = {
      enabled = true,
      view = "cmdline_popup",
      clear_on_escape = true,
      format = {
        width = 25,
        spacing = 4,
        separator = "→",
      },
    },
    -- Visual appearance
    popupmenu = {
      enabled = true,
      backend = "nui",
      kind_icons = {},
    },
    commands = {
      history = {
        view = "popup",
        opts = { enter = true, format = "details" },
        filter = {
          any = {
            { event = "notify" },
            { error = true },
            { warning = true },
            { event = "msg_show", kind = { "" } },
            { event = "lsp", kind = "message" },
          },
        },
      },
      last = {
        view = "popup",
        opts = { enter = true, format = "details" },
        filter = {
          any = {
            { event = "notify" },
            { error = true },
            { warning = true },
            { event = "msg_show", kind = { "" } },
            { event = "lsp", kind = "message" },
          },
        },
        filter_opts = { count = 1 },
      },
      errors = {
        view = "popup",
        opts = { enter = true, format = "details" },
        filter = { error = true },
        filter_opts = { reverse = true },
      },
    },
    lsp = {
      progress = {
        enabled = true,
        format = "lsp_progress",
        format_done = "lsp_progress_done",
        throttle = 1000 / 30,
        view = "mini",
      },
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
      hover = {
        enabled = true,
        view = "hover",
        silent = false,
      },
      signature = {
        enabled = true,
        auto_open = {
          enabled = true,
          trigger = true,
          luasnip = true,
          throttle = 50,
        },
        view = "signature",
      },
      message = {
        enabled = true,
        view = "notify",
        opts = {},
      },
      documentation = {
        view = "hover",
        opts = {
          lang = "markdown",
          replace = true,
          render = "plain",
          format = { "{message}" },
          win_options = { concealcursor = "n", conceallevel = 3 },
        },
      },
    },
    markdown = {
      hover = {
        ["|(%S-)|"] = vim.cmd.help,
        ["%[.-%]%((%S-)%)"] = require("noice.util").open,
      },
      highlights = {
        ["|%S-|"] = "@text.reference",
        ["@%S+"] = "@parameter",
        ["^%s*(Parameters:)"] = "@text.title",
        ["^%s*(Return:)"] = "@text.title",
        ["^%s*(See also:)"] = "@text.title",
        ["{%S-}"] = "@parameter",
      },
    },
    smart_move = {
      enabled = true,
      excluded_filetypes = { "cmp_menu", "cmp_docs", "notify" },
    },
    presets = {
      bottom_search = true,
      command_palette = true,
      long_message_to_split = true,
      inc_rename = true,
      lsp_doc_border = true,
    },
  })
end

return M