local M = {}
local config = require("sysinit.utils.config")

local last_prompts = {}

local history_dir = "/tmp"
local history_files = {}
local current_history_index = {}

local function escape_lua_pattern(s)
  return (s:gsub("(%W)", "%%%1"))
end

local function lsp_request(method, params, timeout)
  local ok, result = pcall(vim.lsp.buf_request_sync, 0, method, params, timeout or 500)
  if not ok or not result then
    return nil
  end
  for _, res in pairs(result) do
    if res.result then
      return res.result
    end
  end
  return nil
end

local function get_history_file(termname)
  if not history_files[termname] then
    history_files[termname] = string.format("%s/ai-terminals-history-%s.txt", history_dir, termname)
  end
  return history_files[termname]
end

local function save_to_history(termname, prompt)
  if not prompt or prompt == "" then
    return
  end

  local history_file = get_history_file(termname)
  local file = io.open(history_file, "a")
  if file then
    file:write(string.format("%s|%s\n", os.date("%Y-%m-%d %H:%M:%S"), prompt))
    file:close()
  end
end

local function load_history(termname)
  local history_file = get_history_file(termname)
  local history = {}
  local file = io.open(history_file, "r")
  if file then
    for line in file:lines() do
      local timestamp, prompt = line:match("^(.-)|(.*)")
      if timestamp and prompt then
        table.insert(history, { timestamp = timestamp, prompt = prompt })
      end
    end
    file:close()
  end
  return history
end

local function create_history_picker(termname)
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope not available", vim.log.levels.ERROR)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local history_data = {}

  if termname then
    local history = load_history(termname)
    for _, entry in ipairs(history) do
      table.insert(history_data, {
        display = string.format("[%s] %s: %s", termname, entry.timestamp, entry.prompt),
        prompt = entry.prompt,
        terminal = termname,
        timestamp = entry.timestamp,
      })
    end
  else
    local agents = { "opencode", "goose", "claude", "cursor" }
    for _, agent in ipairs(agents) do
      local history = load_history(agent)
      for _, entry in ipairs(history) do
        table.insert(history_data, {
          display = string.format("[%s] %s: %s", agent, entry.timestamp, entry.prompt),
          prompt = entry.prompt,
          terminal = agent,
          timestamp = entry.timestamp,
        })
      end
    end

    table.sort(history_data, function(a, b)
      return a.timestamp > b.timestamp
    end)
  end

  pickers
    .new({}, {
      prompt_title = termname and (termname .. " History") or "AI Terminals History",
      finder = finders.new_table({
        results = history_data,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            vim.fn.setreg("+", selection.value.prompt)
            vim.notify(
              "Copied to clipboard: " .. selection.value.prompt:sub(1, 50) .. "...",
              vim.log.levels.INFO
            )
          end
        end)
        return true
      end,
    })
    :find()
end

local function setup_goose_keymaps()
  vim.api.nvim_create_autocmd("TermEnter", {
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local term_name = vim.api.nvim_buf_get_name(buf)

      if term_name:match("goose") then
        vim.keymap.set("t", "<S-CR>", "<C-j>", {
          buffer = buf,
          silent = true,
          desc = "Send Ctrl+J in goose terminal",
        })
      end
    end,
  })
end

local function current_position()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  local handle = io.popen("git rev-parse --show-toplevel")
  local repo_root = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
  handle:close()

  if repo_root and repo_root ~= "" then
    file = file:sub(#repo_root + 2)
  end

  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return { buf = buf, file = file, line = line, col = col }
end

local function get_line_diagnostics(state)
  local diags = vim.diagnostic.get(state.buf, { lnum = state.line - 1 }) or {}
  if #diags == 0 then
    return ""
  end
  return table.concat(
    vim.tbl_map(function(d)
      return string.format("Line %d: %s", d.lnum + 1, d.message)
    end, diags),
    "; "
  )
end

local function get_all_diagnostics(state)
  local diags = vim.diagnostic.get(state.buf) or {}
  if #diags == 0 then
    return ""
  end
  local grouped = {}
  for _, d in ipairs(diags) do
    local severity = vim.diagnostic.severity[d.severity] or "INFO"
    table.insert(grouped, string.format("[%s] Line %d: %s", severity, d.lnum + 1, d.message))
  end
  return table.concat(grouped, "\n")
end

local function get_buffer_path(state)
  if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return ""
  end

  local path = vim.api.nvim_buf_get_name(state.buf)
  if path == "" then
    return ""
  end

  local handle = io.popen("git rev-parse --show-toplevel")
  local repo_root = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
  handle:close()

  if repo_root and repo_root ~= "" then
    path = path:sub(#repo_root + 2)
  end

  return "@" .. path
end

local function get_all_buffers_summary()
  local handle = io.popen("git rev-parse --show-toplevel")
  local repo_root = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
  handle:close()

  local bufs = vim.api.nvim_list_bufs()
  local items = {}
  for _, b in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_option(b, "buflisted") then
      local name = vim.api.nvim_buf_get_name(b)
      if name ~= "" then
        if repo_root and repo_root ~= "" and name:sub(1, #repo_root) == repo_root then
          name = name:sub(#repo_root + 2)
        end
        table.insert(items, name)
      end
    end
  end
  return table.concat(items, "\n")
end

local function get_visual_selection()
  local save_reg = vim.fn.getreg('"')
  local save_regtype = vim.fn.getregtype('"')
  vim.cmd('normal! gv"gy')
  local selection = vim.fn.getreg('"')
  vim.fn.setreg('"', save_reg, save_regtype)
  return selection or ""
end

local function get_visible_content(state)
  local win = vim.api.nvim_get_current_win()
  local top_line = vim.fn.line("w0")
  local bottom_line = vim.fn.line("w$")
  local bufnr = state.buf
  local lines = vim.api.nvim_buf_get_lines(bufnr, top_line - 1, bottom_line, false)
  return table.concat(lines, "\n")
end

local function get_hover_docs(state)
  local params = vim.lsp.util.make_position_params()
  local result = lsp_request("textDocument/hover", params)
  if not result then
    return ""
  end
  local contents = result.contents
  local out = {}
  if type(contents) == "string" then
    table.insert(out, contents)
  elseif vim.tbl_islist(contents) then
    for _, c in ipairs(contents) do
      if type(c) == "string" then
        table.insert(out, c)
      elseif type(c) == "table" and c.value then
        table.insert(out, c.value)
      end
    end
  elseif type(contents) == "table" and contents.value then
    table.insert(out, contents.value)
  end
  return table.concat(out, "\n")
end

local function get_code_actions(state)
  local params = vim.lsp.util.make_range_params()
  params.context = { diagnostics = vim.diagnostic.get(state.buf) }
  local result = lsp_request("textDocument/codeAction", params)
  if not result or #result == 0 then
    return ""
  end
  local titles = {}
  for _, action in ipairs(result) do
    if action.title then
      table.insert(titles, action.title)
    end
  end
  return table.concat(titles, "; ")
end

local function get_quickfix_list()
  local qflist = vim.fn.getqflist()
  if #qflist == 0 then
    return "No quickfix entries"
  end
  local entries = {}
  for _, entry in ipairs(qflist) do
    if entry.valid == 1 then
      local bufname = vim.api.nvim_buf_get_name(entry.bufnr)
      local filename = vim.fn.fnamemodify(bufname, ":t")
      local text = entry.text or ""
      table.insert(entries, string.format("%s:%d: %s", filename, entry.lnum, text))
    end
  end
  return table.concat(entries, "\n")
end

local function get_location_list()
  local loclist = vim.fn.getloclist(0)
  if #loclist == 0 then
    return "No location list entries"
  end
  local entries = {}
  for _, entry in ipairs(loclist) do
    if entry.valid == 1 then
      local bufname = vim.api.nvim_buf_get_name(entry.bufnr)
      local filename = vim.fn.fnamemodify(bufname, ":t")
      local text = entry.text or ""
      table.insert(entries, string.format("%s:%d: %s", filename, entry.lnum, text))
    end
  end
  return table.concat(entries, "\n")
end

local function get_git_diff(state)
  local bufnr = state.buf
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then
    return "No file path available"
  end
  local cmd = string.format("git diff %s", vim.fn.shellescape(filepath))
  local output = vim.fn.system(cmd)
  if output == "" then
    vim.notify("No git diff available for " .. filepath, vim.log.levels.WARN)
    return "No git diff available"
  end
  return output
end

local function populate_qflist_with_diff(state)
  local filepath = vim.api.nvim_buf_get_name(state.buf)
  if filepath == "" then
    return "No file path available"
  end
  local cmd = string.format("git diff --no-color %s", vim.fn.shellescape(filepath))
  local output = vim.fn.systemlist(cmd)
  if output == nil or #output == 0 then
    vim.notify("No diff changes to populate for " .. filepath, vim.log.levels.WARN)
    return "No diff changes to populate"
  end

  local qf_entries = {}
  local current_file = filepath
  local lnum = 0
  for _, line in ipairs(output) do
    if line:match("^@@") then
      local new_lnum = line:match("^@@ %-%d+,%d+ %+(%d+),")
      if new_lnum then
        lnum = tonumber(new_lnum) - 1
      end
    elseif line:match("^%+") and not line:match("^%+%+%+") then
      lnum = lnum + 1
      table.insert(qf_entries, {
        filename = current_file,
        lnum = lnum,
        text = line:sub(2),
        type = "I",
      })
    elseif line:match("^%-") and not line:match("^%-%-%-") then
      table.insert(qf_entries, {
        filename = current_file,
        lnum = lnum,
        text = "Removed: " .. line:sub(2),
        type = "W",
      })
    end
  end

  if #qf_entries > 0 then
    vim.fn.setqflist(qf_entries, "r")
    return "Quickfix list populated with diff changes"
  else
    vim.notify("No diff changes to populate for " .. filepath, vim.log.levels.WARN)
    return "No diff changes to populate"
  end
end

local function open_native_diff(state)
  local filepath = vim.api.nvim_buf_get_name(state.buf)
  if filepath == "" then
    return "No file path available"
  end

  local temp_file = vim.fn.tempname()
  local cmd = string.format(
    "git show HEAD:%s > %s",
    vim.fn.shellescape(filepath),
    vim.fn.shellescape(temp_file)
  )
  local result = vim.fn.system(cmd)
  if result ~= "" then
    vim.notify("Failed to retrieve git HEAD version for " .. filepath, vim.log.levels.WARN)
    vim.fn.delete(temp_file)
    return "Failed to retrieve git HEAD version"
  end

  vim.cmd("vsplit " .. temp_file)
  local new_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(new_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(new_buf, "bufhidden", "wipe")
  vim.cmd("diffthis")
  vim.cmd("wincmd p")
  vim.cmd("diffthis")

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = new_buf,
    callback = function()
      vim.fn.delete(temp_file)
    end,
    once = true,
  })

  return "Native diff view opened"
end

local function open_diff_view(state)
  local has_diffview, _ = pcall(require, "diffview")
  if has_diffview then
    local filepath = vim.api.nvim_buf_get_name(state.buf)
    if filepath == "" then
      return "No file path available"
    end
    vim.cmd("DiffviewOpen -- " .. vim.fn.fnameescape(filepath))
    return "Diffview opened"
  else
    return open_native_diff(state)
  end
end

local PLACEHOLDERS = {
  {
    token = "@cursor",
    description = "Cursor position (file:line)",
    provider = function(state)
      return string.format("%s:%d", get_buffer_path(state), state.line)
    end,
  },
  {
    token = "@selection",
    description = "Selected text",
    provider = get_visual_selection,
  },
  {
    token = "@buffer",
    description = "Current buffer's file path",
    provider = get_buffer_path,
  },
  {
    token = "@buffers",
    description = "List of open buffers",
    provider = get_all_buffers_summary,
  },
  {
    token = "@visible",
    description = "Visible text in the current window",
    provider = get_visible_content,
  },
  {
    token = "@diagnostic",
    description = "Diagnostics for the current line",
    provider = get_line_diagnostics,
  },
  {
    token = "@diagnostics",
    description = "All diagnostics in the current buffer",
    provider = get_all_diagnostics,
  },
  {
    token = "@qflist",
    description = "Quickfix list entries",
    provider = get_quickfix_list,
  },
  {
    token = "@loclist",
    description = "Location list entries",
    provider = get_location_list,
  },
  {
    token = "@diff",
    description = "Git diff for the current buffer",
    provider = get_git_diff,
  },
  {
    token = "@docs",
    description = "LSP hover documentation at cursor",
    provider = get_hover_docs,
  },
  {
    token = "@codeactions",
    description = "Available LSP code action titles",
    provider = get_code_actions,
  },
}

local function apply_placeholders(input)
  if not input or input == "" then
    return input
  end
  local state = current_position()
  local result = input
  for _, ph in ipairs(PLACEHOLDERS) do
    if result:find(ph.token, 1, true) then
      local ok, value = pcall(ph.provider, state)
      value = ok and value or ""
      result = result:gsub(escape_lua_pattern(ph.token), value)
    end
  end
  return result
end

M.placeholder_descriptions = vim.tbl_map(function(p)
  return { token = p.token, description = p.description }
end, PLACEHOLDERS)

local blink_source = {}
local blink_source_setup_done = false

function blink_source.setup()
  if blink_source_setup_done then
    return
  end
  local ok, blink = pcall(require, "blink.cmp")
  if not ok then
    return
  end
  blink.add_source_provider(
    "ai_placeholders",
    { module = "sysinit.plugins.intellicode.ai-terminals", name = "ai_placeholders" }
  )
  blink.add_filetype_source("ai_terminals_input", "ai_placeholders")
  blink_source_setup_done = true
end

function blink_source.new(opts)
  return setmetatable({}, { __index = blink_source }):init(opts or {})
end

function blink_source:init(opts)
  self.opts = opts
  return self
end

function blink_source:enabled()
  return vim.bo.filetype == "ai_terminals_input"
end

function blink_source:get_trigger_characters()
  return { "@" }
end

function blink_source:get_completions(_, callback)
  local items = {}
  local types_ok, types = pcall(require, "blink.cmp.types")
  if not types_ok then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return function() end
  end
  for _, p in ipairs(M.placeholder_descriptions) do
    table.insert(items, {
      label = p.token,
      kind = types.CompletionItemKind.Enum,
      filterText = p.token,
      insertText = p.token,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      documentation = {
        kind = "markdown",
        value = string.format("`%s`\n\n%s", p.token, p.description),
      },
    })
  end
  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
  return function() end
end

function blink_source:resolve(item, callback)
  callback(item)
end

M.new = blink_source.new
M.setup_blink_source = blink_source.setup

M.plugins = {
  {
    "aweis89/ai-terminals.nvim",
    enabled = config.is_agents_enabled(),
    dependencies = { "folke/snacks.nvim" },
    config = function()
      M.setup_blink_source()
      require("ai-terminals").setup({
        backend = "snacks",
        default_position = "right",
        trigger_formatting = {
          enabled = true,
          notify = false,
        },
        watch_cwd = {
          enabled = true,
          ignore = {
            "**/.git/**",
            "**/node_modules/**",
            "**/.venv/**",
            "**/*.log",
            "**/bin/**",
            "**/dist/**",
            "**/vendor/**",
          },
          gitignore = true,
        },
        env = {
          PAGER = "bat",
        },
      })

      setup_goose_keymaps()
    end,
    keys = function()
      local ai_terminals = require("ai-terminals")
      local snacks = require("snacks")

      local function create_input(termname, agent_icon, opts)
        opts = opts or {}
        local action_name = opts.action or "Ask"
        local prompt = string.format("%s  %s", agent_icon, action_name)
        local title = string.format("%s  %s", agent_icon or "", action_name)

        local history = load_history(termname)
        current_history_index[termname] = #history + 1

        snacks.input({
          prompt = prompt,
          title = title,
          icon = agent_icon,
          default = opts.default or "",
          win = {
            b = { completion = true },
            bo = { filetype = "ai_terminals_input" },
            relative = "cursor",
            style = "minimal",
            border = "rounded",
            width = 32,
            height = 1,
            row = 0,
            col = 1,
          },
        }, function(value)
          if opts.on_confirm and value and value ~= "" then
            save_to_history(termname, value)
            opts.on_confirm(apply_placeholders(value))
          end
        end)

        vim.defer_fn(function()
          local buf = vim.api.nvim_get_current_buf()
          if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "ai_terminals_input" then
            vim.keymap.set("n", "j", function()
              if current_history_index[termname] < #history then
                current_history_index[termname] = current_history_index[termname] + 1
                local entry = history[current_history_index[termname]]
                if entry then
                  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(entry.prompt, "\n"))
                end
              end
            end, { buffer = buf, silent = true })

            vim.keymap.set("n", "k", function()
              if current_history_index[termname] > 1 then
                current_history_index[termname] = current_history_index[termname] - 1
                local entry = history[current_history_index[termname]]
                if entry then
                  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(entry.prompt, "\n"))
                end
              elseif current_history_index[termname] == 1 then
                current_history_index[termname] = #history + 1
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
              end
            end, { buffer = buf, silent = true })
          end
        end, 100)
      end

      local function ensure_terminal_and_send(termname, text)
        last_prompts[termname] = text

        local term_info = ai_terminals.get_term_info and ai_terminals.get_term_info(termname)

        if not term_info or not term_info.visible then
          ai_terminals.open(termname)
          ai_terminals.focus()

          vim.defer_fn(function()
            ai_terminals.send_term(termname, text, { submit = true })
          end, 300)
        else
          ai_terminals.focus()
          vim.defer_fn(function()
            ai_terminals.send_term(termname, text, { submit = true })
          end, 300)
        end
      end

      local function create_keymaps(agent)
        local key_prefix, termname, label, icon = agent[1], agent[2], agent[3], agent[4]
        return {
          {
            string.format("<leader>%s%s", key_prefix, key_prefix),
            function()
              ai_terminals.toggle(termname)
            end,
            desc = "Toggle " .. label,
          },
          {
            string.format("<leader>%sv", key_prefix),
            function()
              local last_prompt = last_prompts[termname]
              if last_prompt and last_prompt ~= "" then
                ensure_terminal_and_send(termname, last_prompt)
              else
                vim.notify("No previous prompt found for " .. label, vim.log.levels.WARN)
              end
            end,
            desc = "Resend previous prompt to " .. label,
          },
          {
            string.format("<leader>%sa", key_prefix),
            function()
              local mode = vim.fn.mode()
              local default_text = mode:match("[vV]") and " @selection: " or " @cursor: "
              create_input(termname, icon, {
                action = "Ask",
                default = default_text,
                on_confirm = function(text)
                  ensure_terminal_and_send(termname, text)
                end,
              })
            end,
            mode = { "n", "v" },
            desc = "Ask " .. label,
          },
          {
            string.format("<leader>%sf", key_prefix),
            function()
              create_input(termname, icon, {
                action = "Fix diagnostics",
                default = " Fix @diagnostic: ",
                on_confirm = function(text)
                  ensure_terminal_and_send(termname, text)
                end,
              })
            end,
            desc = "Fix diagnostics with " .. label,
          },
          {
            string.format("<leader>%sc", key_prefix),
            function()
              local mode = vim.fn.mode()
              local default_text = mode:match("[vV]") and " Comment @selection: "
                or " Comment @cursor: "
              create_input(termname, icon, {
                action = "Comment",
                default = default_text,
                on_confirm = function(text)
                  ensure_terminal_and_send(termname, text)
                end,
              })
            end,
            mode = { "n", "v" },
            desc = "Comment with " .. label,
          },
          {
            string.format("<leader>%sq", key_prefix),
            function()
              create_input(termname, icon, {
                action = "Analyze quickfix list",
                default = " Analyze @qflist: ",
                on_confirm = function(text)
                  ensure_terminal_and_send(termname, text)
                end,
              })
            end,
            desc = "Send quickfix list to " .. label,
          },
          {
            string.format("<leader>%sl", key_prefix),
            function()
              create_input(termname, icon, {
                action = "Analyze location list",
                default = " Analyze @loclist: ",
                on_confirm = function(text)
                  ensure_terminal_and_send(termname, text)
                end,
              })
            end,
            desc = "Send location list to " .. label,
          },
          {
            string.format("<leader>%sd", key_prefix),
            function()
              local state = current_position()
              local result = open_diff_view(state)
              if result ~= "Diffview opened" and result ~= "Native diff view opened" then
                vim.notify(result, vim.log.levels.WARN)
              end
            end,
            desc = "View diff with " .. label,
          },
          {
            string.format("<leader>%sp", key_prefix),
            function()
              local state = current_position()
              local result = populate_qflist_with_diff(state)
              if result ~= "Quickfix list populated with diff changes" then
                vim.notify(result, vim.log.levels.WARN)
              else
                vim.notify(result, vim.log.levels.INFO)
              end
            end,
            desc = "Populate quickfix with diff for " .. label,
          },
        }
      end

      local agents = {
        {
          "h",
          "opencode",
          "OpenCode",
          "󰫼󰫰",
        },
        {
          "j",
          "goose",
          "Goose",
          "",
        },
        {
          "y",
          "claude",
          "Claude",
          "󰿟󰫮",
        },
        {
          "u",
          "cursor",
          "Cursor",
          "",
        },
      }

      local all_keymaps = vim.iter(agents):fold({}, function(acc, agent)
        return vim.list_extend(acc, create_keymaps(agent))
      end)

      for _, agent in ipairs(agents) do
        local key_prefix, termname, label = agent[1], agent[2], agent[3]
        table.insert(all_keymaps, {
          string.format("<leader>%sr", key_prefix),
          function()
            create_history_picker(termname)
          end,
          desc = "Browse " .. label .. " history",
        })
        table.insert(all_keymaps, {
          string.format("<leader>%sR", key_prefix),
          function()
            create_history_picker(nil)
          end,
          desc = "Browse all AI terminals history",
        })
      end

      vim.api.nvim_create_autocmd("TermEnter", {
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          local term_name = vim.api.nvim_buf_get_name(buf)

          local current_termname = nil
          for _, agent in ipairs(agents) do
            if term_name:match(agent[2]) then
              current_termname = agent[2]
              break
            end
          end

          if current_termname then
            vim.keymap.set("t", "<localleader>h", function()
              create_history_picker(current_termname)
            end, {
              buffer = buf,
              silent = true,
              desc = "Browse terminal history",
            })
          end
        end,
      })

      return all_keymaps
    end,
  },
}

return M
