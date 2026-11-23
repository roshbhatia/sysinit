local view = require("sysinit_workbench.view")
local M = {}

local function options(args)
  local root = vim.fn.getcwd()
  local recursive = false
  local argv = { "workspace" }
  local i = 2
  while i <= #args do
    local value = args[i]
    if value == "--root" or value == "-root" then
      i = i + 1
      root = assert(args[i], "--root requires a directory")
    elseif value:match("^%-%-?root=") then
      root = value:match("=(.*)$")
    elseif value == "--recursive" or value == "-r" or value == "-recursive" then
      recursive = true
    elseif value == "--staged" or value == "-staged" then
      vim.list_extend(argv, { "--view", "staged" })
    else
      table.insert(argv, value)
    end
    i = i + 1
  end
  return vim.fn.fnamemodify(root, ":p"), recursive, argv
end

local function display(program, cwd, args)
  local buffer = view.buffer("changes://workspace", "sysinit-changes")
  local links = {}
  local current
  local generation = 0
  local function render(snapshot)
    local root = assert(vim.uv.fs_realpath(snapshot.repository.root))
    local lines = {
      ("Changes · %s · %s"):format(snapshot.repository.name, snapshot.comparison.kind),
      "Enter open file  p rendered diff  r refresh  q close",
      "",
    }
    links = {}
    local function add(text, path, line)
      table.insert(lines, text)
      if path then
        links[#lines] = { root = root, path = path, line = line }
      end
    end
    local files = {}
    for _, file in ipairs(snapshot.files or {}) do
      files[file.path] = file
    end
    local function add_file(file)
      add(("  %s  +%d −%d"):format(file.path, file.added, file.deleted), file.path)
      if snapshot.comparison.kind == "working" then
        for _, hunk in ipairs(file.hunks or {}) do
          if hunk.newStart > 0 then
            add(
              ("    %d  %s"):format(hunk.newStart, hunk.symbol or "Changed lines"),
              file.path,
              hunk.newStart
            )
          end
        end
      end
      files[file.path] = nil
    end
    for _, group in ipairs(snapshot.groups or {}) do
      add(group.title)
      if group.summary and group.summary ~= "" then
        add("  " .. group.summary:gsub("[\r\n]", " "))
      end
      for _, path in ipairs(group.files or {}) do
        if files[path] then
          add_file(files[path])
        end
      end
    end
    for _, file in ipairs(snapshot.files or {}) do
      if files[file.path] then
        add_file(file)
      end
    end
    if #(snapshot.files or {}) == 0 then
      add("No changed files")
    end
    if #(snapshot.threads or {}) > 0 then
      add("")
      add("Review notes")
      for _, thread in ipairs(snapshot.threads) do
        local line = snapshot.comparison.kind == "working" and thread.side ~= "left" and thread.line
          or nil
        local first = (thread.comments or {})[1]
        local text = first and (first.summary or "") or ""
        add(
          ("  %s:%s  %s"):format(thread.path, thread.line or "?", text:gsub("[\r\n]", " ")),
          line and thread.path or nil,
          line
        )
      end
    end
    for _, failure in ipairs(snapshot.failures or {}) do
      add(
        ("Provider %s: %s"):format(failure.source or "unknown", failure.message):gsub("[\r\n]", " ")
      )
    end
    view.render(buffer, lines)
  end

  local function load(refresh)
    generation = generation + 1
    local request = generation
    local argv = vim.list_extend({ program }, args)
    if refresh then
      table.insert(argv, "--refresh")
    end
    view.query(argv, cwd, function(err, output)
      if request ~= generation or not vim.api.nvim_buf_is_valid(buffer) then
        return
      end
      local ok, snapshot = pcall(vim.json.decode, output or "")
      if
        err
        or not ok
        or type(snapshot) ~= "table"
        or snapshot.version ~= "changes.workspace/v1"
      then
        local message = err or "Unsupported Changes workspace response"
        if current then
          vim.notify(message, vim.log.levels.WARN)
        else
          view.render(buffer, vim.split(message, "\n", { plain = true }))
        end
        return
      end
      current = snapshot
      render(snapshot)
    end)
  end
  vim.keymap.set("n", "<CR>", function()
    local target = links[vim.fn.line(".")]
    if target then
      view.open_file(target.root, target.path, target.line)
    end
  end, { buffer = buffer })
  vim.keymap.set("n", "p", function()
    if current then
      local diff = view.buffer("changes://diff", "diff")
      view.render(diff, vim.split(current.rendered, "\n", { plain = true }))
    end
  end, { buffer = buffer })
  vim.keymap.set("n", "r", function()
    load(true)
  end, { buffer = buffer })
  vim.keymap.set("n", "q", "<cmd>tabclose<CR>", { buffer = buffer })
  view.render(buffer, { "Loading Changes…" })
  load(false)
end

function M.open(query)
  local cwd, recursive, argv = options(query.args)
  if not recursive then
    return display(query.program, cwd, argv)
  end
  view.query({ "ws", "roots", cwd }, cwd, function(err, output)
    if err then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
    vim.ui.select(
      vim.split(output, "\n", { trimempty = true }),
      { prompt = "Changes repository" },
      function(root)
        if root then
          display(query.program, root, argv)
        end
      end
    )
  end)
end

return M
