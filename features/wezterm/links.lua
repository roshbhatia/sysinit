local wezterm = require("wezterm")
local M = {}

local local_domains = { ["local"] = true, unix = true, TermWizTerminalDomain = true }

function M.configure_mouse(config)
  for _, binding in ipairs(config.mouse_bindings) do
    if binding.mods == "SUPER" and binding.mouse_reporting then
      local down, up = binding.event.Down, binding.event.Up
      -- WezTerm can reset a mouse-reporting pane's viewport between press and release.
      if down and down.button == "Left" and down.streak == 1 then
        binding.action = wezterm.action.OpenLinkAtMouseCursor
      elseif up and up.button == "Left" and up.streak == 1 then
        binding.action = wezterm.action.Nop
      end
    end
  end
end

function M.configure_hyperlinks(config)
  table.insert(config.hyperlink_rules, 1, {
    regex = [[(review://changes/(?:[A-Za-z0-9._~%-]+/){1,2}[0-9a-f]{16}(?:\?turn=[0-9a-f]{16})?)(?![A-Za-z0-9._~%/?=-])]],
    format = "$1",
  })
end

local function parse_file(uri)
  local ok, url = pcall(wezterm.url.parse, uri)
  if not ok or not url.file_path then
    return nil
  end
  local host = (url.host or ""):lower()
  if host == "" or host == "localhost" or host == wezterm.hostname():lower() then
    return url
  end
end

local function source_position(pane, reference, home)
  local name, line, column = reference:match("^(.*):(%d+):(%d+)$")
  if not name then
    name, line = reference:match("^(.*):(%d+)$")
  end
  local path = name or reference
  if path:sub(1, 2) == "~/" then
    path = home .. path:sub(2)
  elseif path:sub(1, 1) ~= "/" then
    local cwd = pane:get_current_working_dir()
    if not cwd or not cwd.file_path then
      return nil
    end
    path = cwd.file_path .. "/" .. path
  end
  return path, line, column
end

function M.setup(options)
  local function run(window, title, command)
    local args = { "/usr/bin/env", "PATH=" .. options.path }
    for _, arg in ipairs(command) do
      args[#args + 1] = arg
    end
    local ok, output, err = wezterm.run_child_process(args)
    if ok then
      return output
    end
    local message = err and err ~= "" and err or "Command failed"
    wezterm.log_error(title .. ": " .. message)
    window:toast_notification(title, message, nil, 4000)
  end

  local function can_review(window, pane)
    if local_domains[pane:get_domain_name()] then
      return true
    end
    window:toast_notification("Review changes", "Run agent-diff in the remote shell", nil, 4000)
    return false
  end

  local function open_review(window, pane, directory, turn)
    local command = {
      options.bin .. "/agent-diff",
      "--pane-id=" .. pane:pane_id(),
      "--cwd=" .. directory,
    }
    if turn then
      command[#command + 1] = "--turn=" .. turn
    end
    if window:get_dimensions().is_full_screen then
      command[#command + 1] = "--fullscreen"
    end
    table.insert(command, 1, "PATH=" .. options.path)
    table.insert(command, 1, "/usr/bin/env")
    local ok, err = pcall(wezterm.background_child_process, command)
    if not ok then
      wezterm.log_error("Review changes: " .. tostring(err))
      window:toast_notification("Review changes", tostring(err), nil, 4000)
    end
  end

  wezterm.on("open-uri", function(window, pane, uri)
    local legacy_id = uri:match("^review://([0-9a-f]+)$")
    if
      uri:match("^review://changes/")
      or uri:match("^review://worktree/")
      or (legacy_id and #legacy_id == 16)
    then
      if not can_review(window, pane) then
        return false
      end
      local resolved = run(
        window,
        "Review changes",
        { options.bin .. "/agent-review-link", "--resolve", uri, "--json" }
      )
      if resolved then
        local target = wezterm.json_parse(resolved)
        open_review(window, pane, target.directory, target.turn)
      end
      return false
    end

    local reference = uri:match("^sysinit%-file:(.+)$")
    local file_link = uri:match("^file:")
    if not reference and not file_link then
      return
    end
    if not local_domains[pane:get_domain_name()] then
      if reference then
        return false
      end
      return
    end

    local path, line, column
    if file_link then
      local url = parse_file(uri)
      if not url then
        return
      end
      path = url.file_path
      line, column = (url.fragment or ""):match("^L?(%d+)[:C](%d+)$")
      line = line or (url.fragment or ""):match("^L?(%d+)")
    else
      path, line, column = source_position(pane, reference, options.home)
      if not path then
        return false
      end
    end

    local ok, output = wezterm.run_child_process({ options.file, "-Lb", "--mime-type", "--", path })
    local mime = ok and output:match("^([^%s]+)") or ""
    if
      line
      or mime:match("^text/")
      or mime:match("[/+]json$")
      or mime:match("[/+]xml$")
      or mime == "application/javascript"
      or mime == "inode/x-empty"
      or mime == "application/x-empty"
    then
      local command = {
        options.bin .. "/ty",
        "pane",
        "spawn",
        tostring(pane:pane_id()),
        "--direction",
        "left",
        "--percent",
        "45",
        "--cwd",
        path:match("^(.+)/[^/]+$") or "/",
        "--",
        options.bin .. "/nvim",
      }
      local row = math.tointeger(line)
      if row then
        command[#command + 1] = ("+call cursor(%d,%d)"):format(row, math.tointeger(column) or 1)
      end
      command[#command + 1] = "--"
      command[#command + 1] = path
      run(window, "Open source", command)
    else
      wezterm.open_with(path)
    end
    return false
  end)

  return {
    brief = "Open Worktree Review",
    action = wezterm.action_callback(function(window, pane)
      if not can_review(window, pane) then
        return
      end
      local cwd = pane:get_current_working_dir()
      if cwd and cwd.file_path then
        open_review(window, pane, cwd.file_path)
      else
        window:toast_notification(
          "Review changes",
          "The focused pane has no working directory",
          nil,
          4000
        )
      end
    end),
  }
end

return M
