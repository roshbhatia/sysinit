local M = {}

local INTERVAL_MS = 1000

---@type uv.uv_timer_t|nil
local timer = nil

local function tick()
  pcall(vim.cmd, "silent! checktime")
end

function M.start()
  if timer then
    return
  end
  if not vim.uv then
    return
  end
  timer = vim.uv.new_timer()
  if not timer then
    return
  end
  timer:start(INTERVAL_MS, INTERVAL_MS, vim.schedule_wrap(tick))
end

---@return boolean
function M.is_active()
  return timer ~= nil
end

function M.stop()
  if not timer then
    return
  end
  pcall(timer.stop, timer)
  pcall(timer.close, timer)
  timer = nil
end

return M
