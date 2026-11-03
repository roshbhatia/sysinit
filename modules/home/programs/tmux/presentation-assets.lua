local function build()
  local wezterm = require("wezterm")
  local root = assert(os.getenv("SYSINIT_WEZTERM_LUA"))
  package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
  local config = require("sysinit.pkg.bootstrap").build()
  local loader = require("sysinit.pkg.plugin_loader")
  local sigil_ok, sigil = loader.load("sigil")
  local tab_ok, tabline = loader.load("tabline")
  assert(sigil_ok and tab_ok, "native presentation plugins must load")
  local settings =
    require("sysinit.pkg.utils").load_json_file(require("sysinit.pkg.utils").get_config_path("config.json"))
  local fonts = {}
  for _, name in ipairs({
    "md_clock_alert",
    "md_check_circle",
    "md_loading",
    "cod_circle_small_filled",
    "md_dock_window",
    "md_tab",
    "md_alert",
    "cod_briefcase",
    "md_lock",
    "md_lock_open",
  }) do
    fonts[name] = wezterm.nerdfonts[name]
  end
  package.path = settings.plugins.tabline .. "/plugin/?.lua;" .. package.path
  local native = require("tabline.config")
  native.set(tabline.get_config())
  local function sections(values)
    local result = {}
    for _, value in ipairs(values) do
      if type(value) == "function" then
        value = "sysinit-tab-index"
      elseif type(value) == "table" and value[1] then
        local component = { component = value[1] }
        for key, option in pairs(value) do
          if key ~= 1 then
            component[key] = option
          end
        end
        value = component
      end
      result[#result + 1] = value
    end
    return result
  end
  local indicator = require("sysinit.pkg.ui.statusbar").locked_indicator
  local encoded = wezterm.json_encode({
    settings = settings,
    nerdfonts = fonts,
    processes = sigil.all(),
    symbols = { Workspace = sigil.symbol("Workspace"), Folder = sigil.symbol("Folder") },
    tabs = tabline.get_theme().tab,
    theme = require("tabline.util").deep_copy(tabline.get_theme()),
    components = native.component_opts,
    tab_sections = { active = sections(native.sections.tab_active), inactive = sections(native.sections.tab_inactive) },
    domain_options = require("tabline.components.window.domain").default_opts,
    mode_icons = { locked = indicator(true), unlocked = indicator(false) },
  })
  local file = assert(io.open(assert(os.getenv("TMUX_PRESENTATION_ASSETS")), "w"))
  file:write(encoded)
  file:close()
  return config
end
local ok, result = xpcall(build, tostring)
if not ok then
  require("wezterm").log_error(tostring(result))
  error(result)
end
return result
