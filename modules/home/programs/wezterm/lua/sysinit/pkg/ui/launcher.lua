local wezterm = require("wezterm")
local command = require("sysinit.pkg.command")
local utils = require("sysinit.pkg.utils")
local actions = require("sysinit.pkg.ui.actions")

local M = {}

local function report(win, message)
  wezterm.log_error(message)
  win:toast_notification("WezTerm", message, nil, 5000)
end

function M.directory_spawn(plan)
  if type(plan) ~= "table" or plan.version ~= "seshy.open/v1" then
    return nil, "Unsupported directory plan"
  end
  if type(plan.cwd) ~= "string" or plan.cwd:sub(1, 1) ~= "/" then
    return nil, "Directory plan has no absolute path"
  end
  if type(plan.command) ~= "table" or #plan.command ~= 0 then
    return nil, "Directory plan must use the default shell"
  end
  if type(plan.environment) ~= "table" then
    return nil, "Directory plan has no environment"
  end
  for key, value in pairs(plan.environment) do
    if type(key) ~= "string" or type(value) ~= "string" then
      return nil, "Directory plan has an invalid environment"
    end
  end
  return { cwd = plan.cwd, domain = { DomainName = "local" }, set_environment_variables = plan.environment }
end

function M.open_directory(win, pane)
  local config = utils.load_json_file(utils.get_config_path("config.json")) or {}
  local source = config.directories or {}
  local rows, err = command.json(source.list)
  if not rows then
    report(win, err)
    return
  end
  local choices, names = {}, {}
  for _, row in ipairs(rows) do
    if type(row) == "table" and type(row.name) == "string" and type(row.path) == "string" then
      choices[#choices + 1] = { id = row.name, label = row.name .. "  " .. row.path }
      names[row.name] = true
    end
  end
  if #choices == 0 then
    report(win, "No directory groups found")
    return
  end
  win:perform_action(
    wezterm.action.InputSelector({
      title = "Open directory group",
      fuzzy = true,
      choices = choices,
      action = wezterm.action_callback(function(inner_win, inner_pane, name)
        if not name or not names[name] then
          return
        end
        local plan, resolve_err = command.json(source.open, name)
        if not plan then
          report(inner_win, resolve_err)
          return
        end
        local spawn, spawn_err = M.directory_spawn(plan)
        if not spawn then
          report(inner_win, spawn_err)
          return
        end
        -- A unique workspace prevents a same-named remote workspace from capturing this local launch.
        local workspace = name .. " [" .. wezterm.uuid_v4():sub(1, 8) .. "]"
        actions.switch_to_workspace(inner_win, inner_pane, workspace, spawn)
      end),
    }),
    pane
  )
end

function M.connect_host(win, pane, domains)
  local choices, known = {}, {}
  for _, domain in ipairs(domains) do
    choices[#choices + 1] = { id = domain.name, label = domain.remote_address or domain.name }
    known[domain.name] = true
  end
  table.sort(choices, function(a, b)
    return a.label < b.label
  end)
  win:perform_action(
    wezterm.action.InputSelector({
      title = "Connect to host",
      fuzzy = true,
      choices = choices,
      action = wezterm.action_callback(function(inner_win, inner_pane, name)
        if name and known[name] then
          inner_win:perform_action(wezterm.action.AttachDomain(name), inner_pane)
        end
      end),
    }),
    pane
  )
end

return M
