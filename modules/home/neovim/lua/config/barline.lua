-- Attempt to load barbar safely
local status_ok, barbar = pcall(require, 'barbar')
if status_ok then
  barbar.setup()
end
