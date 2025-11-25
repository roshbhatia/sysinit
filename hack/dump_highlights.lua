#!/usr/bin/env nvim -l
-- Script to dump and compare telescope and wilder highlight groups

local function get_highlight_groups(pattern)
  local groups = {}
  local hlstrs = vim.fn.getcompletion(pattern, "highlight")

  for _, hl in ipairs(hlstrs) do
    local hl_info = vim.api.nvim_get_hl(0, { name = hl, link = false })
    groups[hl] = hl_info
  end

  return groups
end

local function dump_highlights(prefix, groups)
  print("\n=== " .. prefix .. " Highlight Groups ===\n")

  local sorted_keys = {}
  for key in pairs(groups) do
    table.insert(sorted_keys, key)
  end
  table.sort(sorted_keys)

  for _, key in ipairs(sorted_keys) do
    local hl = groups[key]
    local hl_str = "  " .. key

    if hl.fg then
      hl_str = hl_str .. " fg=" .. string.format("#%06x", hl.fg)
    end
    if hl.bg then
      hl_str = hl_str .. " bg=" .. string.format("#%06x", hl.bg)
    end
    if hl.bold then
      hl_str = hl_str .. " bold"
    end
    if hl.italic then
      hl_str = hl_str .. " italic"
    end
    if hl.underline then
      hl_str = hl_str .. " underline"
    end

    print(hl_str)
  end
end

local function main()
  -- Get Telescope highlight groups
  local telescope_groups = get_highlight_groups("Telescope*")
  dump_highlights("TELESCOPE", telescope_groups)

  -- Get Wilder highlight groups
  local wilder_groups = get_highlight_groups("Wilder*")
  dump_highlights("WILDER", wilder_groups)

  -- Get related menu/selection groups
  local menu_groups = {}
  local menu_patterns = { "Pmenu", "PmenuSel", "WildMenu", "Visual", "Search", "IncSearch", "FloatBorder" }
  for _, pattern in ipairs(menu_patterns) do
    local groups = get_highlight_groups(pattern)
    for key, val in pairs(groups) do
      menu_groups[key] = val
    end
  end
  dump_highlights("RELATED MENU/SELECTION", menu_groups)

  -- Print summary of comparison
  print("\n=== Comparison ===\n")
  print("Telescope groups: " .. vim.fn.len(telescope_groups))
  print("Wilder groups: " .. vim.fn.len(wilder_groups))
  print("Related menu groups: " .. vim.fn.len(menu_groups))

  -- Check for common highlight group references
  print("\n=== Wilder highlight group mappings (from wilder.lua) ===")
  print("  default = Pmenu")
  print("  selected = PmenuSel")
  print("  border = FloatBorder")
  print("  accent = WilderWildmenuAccent")
  print("  selected_accent = WilderWildmenuSelectedAccent")

  print("\n=== Telescope highlight group references (auto-mapped by telescope) ===")
  print("  TelescopeBorder")
  print("  TelescopeNormal")
  print("  TelescopeSelection")
  print("  TelescopeTitle")
  print("  TelescopePromptTitle")
  print("  TelescopePreviewTitle")
  print("  TelescopePromptBorder")
  print("  TelescopePromptCounter")
  print("  TelescopePromptPrefix")
  print("  TelescopePromptNormal")
  print("  TelescopeResultsTitle")
  print("  TelescopeResultsBorder")
  print("  TelescopeResultsNormal")
  print("  TelescopePreviewBorder")
  print("  TelescopePreviewNormal")
  print("  TelescopePreviewLine")
end

main()
