local M = {}

local hidden_patterns = {
  "null%-ls.*failed to run generator",
  "Flake input * cannot be evaluated",
  "Invalid window id: *",
}

local original_notify = vim.notify

vim.notify = function(msg, level, opts)
  if msg then
    for _, pattern in ipairs(hidden_patterns) do
      if msg:match(pattern) then
        return
      end
    end
  end
  return original_notify(msg, level, opts)
end

return M
