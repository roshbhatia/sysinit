local function find_window(file)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_name(buf) == file then
      return win
    end
  end
end

local function review_window(file)
  local reviewr = require("reviewr")
  local ui = require("reviewr.ui")
  ui.focus_tab()
  local state = require("reviewr.state").get()
  local path = state and vim.fs.relpath(state.repo, file)
  if not path then
    return nil
  end
  local includes_file = vim.iter(state.files or {}):any(function(entry)
    return entry.path == path
  end)
  if (state.head_ref or not includes_file) and not reviewr.set_scope("uncommitted") then
    return nil
  end
  if reviewr.open_file(path) then
    return ui.panes().right_win
  end
end

local function jump(position, review)
  local win
  if review then
    win = review_window(position.file)
  else
    vim.wait(750, function()
      win = find_window(position.file)
      return win ~= nil
    end, 20)
  end
  if not win then
    return false
  end
  vim.api.nvim_set_current_win(win)
  if position.line then
    local buf = vim.api.nvim_win_get_buf(win)
    local line = math.min(position.line, vim.api.nvim_buf_line_count(buf))
    local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1] or ""
    local column = math.min(position.column - 1, math.max(#text - 1, 0))
    vim.api.nvim_win_set_cursor(win, { line, column })
    vim.cmd.normal({ "zv", bang = true })
  end
  return true
end

local function mux_cli(args)
  return vim.system(vim.list_extend({ "wezterm", "cli", "--no-auto-start" }, args)):wait(1500)
end

local function foreground_group(tty)
  if type(tty) ~= "string" or tty == "" then
    return nil
  end
  local result = vim.system({ "ps", "-t", tty:gsub("^/dev/", ""), "-o", "tpgid=" }):wait(1000)
  return result.code == 0 and (result.stdout or ""):match("^%s*([1-9]%d*)") or nil
end

local function open_review()
  if vim.v.vim_did_enter == 0 then
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        vim.schedule(open_review)
      end,
    })
    return
  end

  -- The GUI and a persistent mux number the same panes independently.
  -- This editor sees the owning mux, where its right neighbor is the source.
  local pane = vim.env.WEZTERM_PANE
  local result = pane and mux_cli({ "get-pane-direction", "--pane-id", pane, "Right" })
  local origin = result and result.code == 0 and vim.trim(result.stdout or "")
  if not origin or not origin:match("^%d+$") then
    origin = "unavailable"
  end
  local listed = mux_cli({ "list", "--format", "json" })
  local ok, panes = pcall(vim.json.decode, listed.stdout or "")
  local owner = ok
    and type(panes) == "table"
    and vim.iter(panes):find(function(candidate)
      return tostring(candidate.pane_id) == origin
    end)
  local tty = owner and owner.tty_name
  local group = foreground_group(tty)

  vim.env.SYSINIT_REVIEW_PANE = origin
  vim.cmd.SysinitAgentReview()

  local transport = require("reviewr.transport")
  local detect = transport.detect
  transport.detect = function()
    if group and foreground_group(tty) == group then
      return detect(nil)
    end
    return {}
  end
end

local function select_review(refresh)
  local ui = require("reviewr.ui")
  if not ui.is_open() then
    return 0
  end
  ui.focus_tab()
  if refresh then
    require("sysinit_workbench.review").refresh()
  end
  local review_tab = vim.api.nvim_win_get_tabpage(ui.panes().right_win)
  return vim.api.nvim_get_current_tabpage() == review_tab and 1 or 0
end

if vim.env.SYSINIT_DIFFVIEW_ARGS then
  local args = vim.json.decode(vim.env.SYSINIT_DIFFVIEW_ARGS)
  vim.env.SYSINIT_DIFFVIEW_ARGS = nil
  require("diffview").open(args)
end

return { jump = jump, open_review = open_review, select_review = select_review }
