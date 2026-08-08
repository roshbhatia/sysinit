local M = {}

local lifecycle = require("harness.lifecycle")

---@param def { name: string, label: string, cmd: string, args?: string[], percent?: number, side?: "left"|"right", options_schema?: table }
---@return table adapter
function M.raw_cli_adapter(def)
  local lc -- lazy-built per (cmd+options) combo
  local lc_signature -- cached signature of options that produced lc

  local function escape_args(args)
    local out = {}
    for i, a in ipairs(args) do
      out[i] = vim.fn.shellescape(a)
    end
    return out
  end

  local function build_cmd_string()
    local args = vim.deepcopy(def.args or {})
    local opt_args = require("harness.options").build_args(def.name)
    for _, a in ipairs(opt_args) do
      table.insert(args, a)
    end
    if #args == 0 then
      return def.cmd
    end
    return def.cmd .. " " .. table.concat(escape_args(args), " ")
  end

  local function ensure()
    local cmd_string = build_cmd_string()
    if not lc or lc_signature ~= cmd_string then
      if lc and lc.kill then pcall(lc.kill) end
      lc = lifecycle.build(cmd_string, {
        name = def.name,
        percent = def.percent,
        side = def.side,
      })
      lc_signature = cmd_string
    end
    return lc
  end

  return {
    name = def.name,
    label = def.label,
    options_schema = def.options_schema,
    available = function()
      return vim.fn.executable(def.cmd:match("^%S+")) == 1
    end,
    toggle = function()
      ensure().toggle()
    end,
    focus = function()
      ensure().focus()
    end,
    is_visible = function()
      if not lc then
        return false
      end
      return lc.is_visible()
    end,
    send = function(text, opts)
      ensure().send(text, opts or { submit = true })
    end,
    kill = function()
      if lc then
        lc.kill()
        lc = nil
        lc_signature = nil
      end
    end,
  }
end

return M
