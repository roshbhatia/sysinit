Name = "panes"
NamePretty = "Tmux Panes"
Icon = "utilities-terminal"
Action = "@ty@ pane focus %VALUE%"
SearchName = true
History = true

function GetEntries()
  local entries = {}
  local cmd = [[@ty@ panes | @jq@ -r '.panes[] | [
    .pane_id,
    (.session_name // "default"),
    ("window " + (.window_index // "0") + ", pane " + (.pane_index // "0")),
    ""
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
