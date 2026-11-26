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

local file_edges = { "left", "right", "top", "bottom", "auto" }
local edge_moves = { left = "H", right = "L", top = "K", bottom = "J" }
local file_edge = "auto"

local function setup_layout()
  local ui = require("reviewr.ui")
  local last_edge
  ui.equalize = function()
    if not ui.is_open() then
      return
    end
    local diff, panel = ui.panes(), ui.files_panel()
    if not panel.win or not vim.api.nvim_win_is_valid(panel.win) then
      return
    end
    local cols, rows = vim.o.columns, vim.o.lines
    local edge = file_edge == "auto" and (cols >= 136 and "left" or "bottom") or file_edge
    local side = edge == "left" or edge == "right"
    local width = math.min(36, math.max(16, math.floor(cols * 0.22)))
    local stack = cols - (side and width or 0) < 100 and rows >= 22
    local diff_tab = vim.api.nvim_win_get_tabpage(diff.left_win)
    vim.api.nvim_win_call(diff.left_win, function()
      local left = vim.api.nvim_win_get_position(diff.left_win)
      local right = vim.api.nvim_win_get_position(diff.right_win)
      local move_diff = stack ~= (left[1] ~= right[1])
      if move_diff then
        vim.fn.win_splitmove(
          diff.right_win,
          diff.left_win,
          { vertical = not stack, rightbelow = true }
        )
      end
      if edge ~= last_edge or move_diff then
        vim.api.nvim_win_call(panel.win, function()
          vim.cmd.wincmd(edge_moves[edge])
        end)
      end
      last_edge = edge
      vim.wo[panel.win].winfixwidth = side
      vim.wo[panel.win].winfixheight = not side
      if side then
        vim.api.nvim_win_set_width(panel.win, width)
      else
        vim.api.nvim_win_set_height(panel.win, math.min(8, math.max(3, math.floor(rows * 0.19))))
      end
      if #vim.api.nvim_tabpage_list_wins(diff_tab) == 3 then
        local size = stack and vim.api.nvim_win_get_height or vim.api.nvim_win_get_width
        local resize = stack and vim.api.nvim_win_set_height or vim.api.nvim_win_set_width
        resize(diff.left_win, math.floor((size(diff.left_win) + size(diff.right_win)) / 2))
      end
    end)
  end
  local render = ui.open_files_panel
  ui.open_files_panel = function(files)
    local previous = ui.files_panel().win
    if not previous or not vim.api.nvim_win_is_valid(previous) then
      last_edge = nil
    end
    render(files)
  end
  local function place(edge)
    file_edge = edge
    ui.equalize()
  end
  vim.api.nvim_create_user_command("ReviewFiles", function(command)
    if not vim.tbl_contains(file_edges, command.args) then
      error("Expected left, right, top, bottom, or auto")
    end
    place(command.args)
  end, {
    nargs = 1,
    complete = function()
      return file_edges
    end,
  })
  vim.keymap.set("n", "<LocalLeader>w", function()
    for index, edge in ipairs(file_edges) do
      if edge == file_edge then
        place(file_edges[index % #file_edges + 1])
        return
      end
    end
  end, { desc = "Move review file tree" })
  table.insert(require("reviewr.keymaps").legend, {
    (vim.g.maplocalleader or "\\") .. "w",
    "move the file tree",
  })
end

local function open_review(range)
  if vim.v.vim_did_enter == 0 then
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        vim.schedule(function()
          open_review(range)
        end)
      end,
    })
    return
  end

  -- Resolve the adjacent pane in the editor's mux, whose IDs may differ
  -- from those in the GUI that requested the split.
  local pane = vim.env.WEZTERM_PANE
  local listed = mux_cli({ "list", "--format", "json" })
  local ok, panes = pcall(vim.json.decode, listed.stdout or "")
  local owner
  if pane and ok and type(panes) == "table" then
    local own = vim.iter(panes):find(function(candidate)
      return tostring(candidate.pane_id) == pane
    end)
    if own then
      local down = vim.env.SYSINIT_REVIEW_SPLIT == "down"
      owner = vim.iter(panes):find(function(candidate)
        if candidate.tab_id ~= own.tab_id or candidate.pane_id == own.pane_id then
          return false
        end
        if down then
          return candidate.left_col == own.left_col
            and candidate.top_row + candidate.size.rows + 1 == own.top_row
        end
        return candidate.top_row == own.top_row
          and candidate.left_col + candidate.size.cols + 1 == own.left_col
      end)
    end
  end
  local tty = owner and owner.tty_name
  local group = foreground_group(tty)

  setup_layout()
  vim.env.SYSINIT_REVIEW_PANE = owner and tostring(owner.pane_id) or "unavailable"
  local reviewr = require("reviewr")
  local open = reviewr.open
  -- Keep the workbench's index and transport setup, and initialize the
  -- requested scope on its first call into Reviewr.
  if range then
    reviewr.open = function()
      return open({ range[1], range[2], "turn" })
    end
  end
  local opened, err = pcall(require("sysinit_workbench.review").open)
  reviewr.open = open
  if not opened then
    error(err)
  end

  local transport = require("reviewr.transport")
  local detect = transport.detect
  transport.detect = function()
    if group and foreground_group(tty) == group then
      return detect(nil)
    end
    return {}
  end
end

local function select_review(refresh, range)
  local ui = require("reviewr.ui")
  if not ui.is_open() then
    return 0
  end
  ui.focus_tab()
  local state = require("reviewr.state").get()
  if range then
    if state.base_ref ~= range[1] or state.head_ref ~= range[2] then
      require("reviewr").open({ range[1], range[2], "turn" })
    end
  elseif refresh then
    if state.head_ref and state.scope.name == "turn" then
      require("reviewr").set_scope("uncommitted")
    end
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
