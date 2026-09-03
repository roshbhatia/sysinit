Name = "panes"
NamePretty = "WezTerm Panes"
Icon = "utilities-terminal"
Action = "@wezterm@ cli activate-pane --pane-id %VALUE%"
SearchName = true
History = true

-- @menu-prelude@

function GetEntries()
  local entries = {}
  local cmd = [[@wezterm@ cli list --format json | @jq@ -r '.[] | [
    .pane_id,
    (.workspace // "default"),
    (.title // .tab_title // "pane"),
    (.cwd // "")
  ] | @tsv']]
  for _, row in ipairs(lines(cmd)) do
    if row[1] ~= nil and row[1] ~= "" then
      entries[#entries + 1] = {
        Text = row[2] .. ": " .. (row[3] or ""),
        Subtext = row[4] or "",
        Value = row[1],
      }
    end
  end
  return entries
end
