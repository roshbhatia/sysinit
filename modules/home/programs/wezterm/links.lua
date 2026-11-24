local wezterm = require("wezterm")
local M = {}

local local_domains = { ["local"] = true, unix = true, TermWizTerminalDomain = true }

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

  wezterm.on("open-uri", function(window, pane, uri)
    if uri:match("^review://") then
      if not local_domains[pane:get_domain_name()] then
        window:toast_notification("Review diff", "Run agent-diff in the remote shell", nil, 4000)
        return false
      end
      local directory =
        run(window, "Review diff", { options.bin .. "/agent-review-link", "--resolve", uri })
      if directory then
        run(window, "Review diff", {
          options.bin .. "/agent-diff",
          "--pane-id=" .. pane:pane_id(),
          "--cwd=" .. directory:gsub("\n$", ""),
        })
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
end

return M
