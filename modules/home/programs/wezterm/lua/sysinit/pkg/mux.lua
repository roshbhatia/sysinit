local M = {}

-- The GUI becomes a viewer over a server that outlives it. Naming the domain
-- that WezTerm already provides implicitly is what lets `connect unix` find it;
-- the startup args only apply to a bare `wezterm`, so an explicit `wezterm
-- start` still opens a throwaway window in the local domain.
function M.setup(config)
  config.unix_domains = { { name = "unix" } }
  config.default_gui_startup_args = { "connect", "unix" }
end

return M
