local json = require("dkjson")
local source, deck_source, config_file, panes_dir, history_file = table.unpack(arg)
local function read(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local data = json.decode(file:read("*a"))
  file:close()
  return data
end

package.path = source .. "/?.lua;" .. source .. "/?/init.lua;" .. package.path
package.loaded.wezterm = { json_parse = json.decode }
package.loaded["sysinit.pkg.utils"] = {
  state_path = function()
    return panes_dir
  end,
}
local activity = require("sysinit.pkg.ui.activity")
local panes = require("sysinit.pkg.ui.panes")
local detector = dofile(deck_source .. "/plugin/detector.lua")
local agents = assert(read(config_file), "agent detection configuration is missing")
panes.configure(agents)
panes.restore_history(read(history_file))
local snapshot = assert(json.decode(io.read("*a")), "invalid tmux snapshot")
local records, present = {}, {}
for _, row in ipairs(snapshot) do
  local pane = {
    pane_id = function()
      return row.pane
    end,
    get_user_vars = function()
      return {}
    end,
    get_foreground_process_info = function()
      return row.process
    end,
    get_lines_as_text = function()
      return row.text or ""
    end,
    get_title = function()
      return row.title or ""
    end,
  }
  local record = panes.read_pane_record(row.pane)
  local agent = activity.process(pane, agents) or detector.detect_agent(pane, { agents = agents })
  local states = agent and { [row.pane] = { agent = agent } } or {}
  local status, reason, since, name = panes.agent_state(pane, states, record)
  present[row.pane] = true
  if status then
    record = record or {}
    record.pane, record.session = row.pane, row.session
    record.repo = record.repo or row.cwd:match("([^/]+)$") or ""
    record.status, record.reason, record.since, record.agent = status, reason, since, name
    records[#records + 1] = record
  end
end
panes.forget_missing(present)
local history = assert(io.open(history_file .. ".tmp", "w"))
history:write(json.encode(panes.snapshot_history()))
history:close()
assert(os.rename(history_file .. ".tmp", history_file))
io.write(json.encode(records))
