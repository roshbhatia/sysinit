-- The agent runs in a wezterm pane beside this editor, never inside it.
--
-- That is the whole reason this file replaced fifteen adapter modules. An
-- adapter existed to run one agent's CLI in an editor split and had to know that
-- agent's flags to do it. A wezterm pane needs the command and nothing else, so
-- the per-agent knowledge collapses into one generated list and the editor stops
-- being a terminal multiplexer.
--
-- Either half stands alone. With no pane, this editor is still a diff viewer.
-- With no editor, the agent is still an agent.
local M = {}

local REGISTRY = vim.fs.normalize(vim.env.XDG_CONFIG_HOME or "~/.config") .. "/sysinit/agents.json"

---@type table[]|nil
local cached = nil

---@return table[]
local function registry()
  if cached then
    return cached
  end
  cached = {}
  local ok, body = pcall(vim.fn.readfile, REGISTRY)
  if not ok then
    return cached
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(body, "\n"))
  if decoded_ok and type(decoded) == "table" and type(decoded.agents) == "table" then
    cached = decoded.agents
  end
  return cached
end

-- Every declared agent, installed or not. notes.lua needs the uninstalled ones
-- to mark a note whose author is no longer on this machine.
---@return table[]
function M.all()
  return registry()
end

---@return table[]
function M.agents()
  local out = {}
  for _, agent in ipairs(registry()) do
    if type(agent.command) == "string" and vim.fn.executable(agent.command) == 1 then
      out[#out + 1] = agent
    end
  end
  return out
end

local wezterm = require("utils.wezterm_terminal")

-- The remembered pane, or nil once it is gone. Asking wezterm every time is what
-- keeps a killed pane from looking live; nothing tells this editor when a pane
-- closes.
---@return string|nil id, string|nil agent
function M.pane()
  local id = vim.g.harness_pane
  if id == nil or id == "" then
    return nil, nil
  end
  if not wezterm.pane_alive(id) then
    vim.g.harness_pane = nil
    require("harness.session").clear_active()
    return nil, nil
  end
  return tostring(id), require("harness.session").get_active()
end

---@return string
local function root()
  local gitrepo = require("utils.gitrepo")
  return gitrepo.buffer_root() or gitrepo.cwd_root() or vim.fs.normalize(vim.uv.cwd() or ".")
end

---@param agent table
---@return boolean
function M.launch(agent)
  if vim.env.WEZTERM_PANE == nil then
    vim.notify("Harness: not inside wezterm, so there is no pane to split", vim.log.levels.WARN)
    return false
  end

  local id, err = wezterm.split({
    parent = vim.env.WEZTERM_PANE,
    cwd = root(),
    percent = 40,
    argv = { agent.command },
  })
  if not id or id == "" then
    vim.notify("Harness: " .. (err or "wezterm returned no pane id"), vim.log.levels.ERROR)
    return false
  end

  vim.g.harness_pane = id
  require("harness.session").set_active(agent.name)
  return true
end

function M.focus()
  local id = M.pane()
  if not id then
    return false
  end
  wezterm.activate(id)
  return true
end

function M.kill()
  local id = M.pane()
  if id then
    wezterm.kill(id)
  end
  vim.g.harness_pane = nil
  require("harness.session").clear_active()
end

-- Text goes to the pane as a paste, so a multi-line prompt arrives as one block
-- rather than as a line the agent submits early. submit adds the newline.
---@param text string
---@param opts? { submit?: boolean }
---@return boolean
function M.send(text, opts)
  local id = M.pane()
  if not id then
    vim.notify("Harness: no agent pane — start one with <leader>jj", vim.log.levels.WARN)
    return false
  end
  if not wezterm.send_text(id, text, { submit = opts and opts.submit }) then
    vim.notify("Harness: send failed", vim.log.levels.ERROR)
    return false
  end
  return true
end

function M.pick()
  if M.focus() then
    return
  end

  local available = M.agents()
  if #available == 0 then
    vim.notify("Harness: no agent from " .. REGISTRY .. " is on PATH", vim.log.levels.WARN)
    return
  end

  -- No acp marker. This picker starts a TUI in a pane, and nine of the fourteen
  -- carry the flag, so it labelled most of the list without changing any of it.
  local function label(agent)
    local glyph = tostring(agent.glyph or "")
    return glyph ~= "" and (glyph .. "  " .. agent.label) or agent.label
  end

  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker then
    vim.ui.select(available, { prompt = "Start agent:", format_item = label }, function(agent)
      if agent then
        M.launch(agent)
      end
    end)
    return
  end

  local items = {}
  for _, agent in ipairs(available) do
    items[#items + 1] = { agent = agent, text = label(agent) }
  end

  snacks.picker.pick({
    source = "harness_agents",
    items = items,
    title = "Start agent in a wezterm pane",
    format = function(item)
      return { { item.text, "Normal" } }
    end,
    layout = { preset = "select" },
    confirm = function(picker, item)
      picker:close()
      if item then
        M.launch(item.agent)
      end
    end,
  })
end

---@return table
function M.status()
  local id, agent = M.pane()
  return { pane = id, agent = agent, available = #M.agents(), registry = REGISTRY }
end

return M
