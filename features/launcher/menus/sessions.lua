Name = "sessions"
NamePretty = "Sessions"
Icon = "utilities-terminal"
Action = "@ty@ session launch %VALUE%"
SearchName = true
History = true

function GetEntries()
  local entries = {}
  local cmd = [[@sy@ list --json | @jq@ -r '.[] | [
    .id,
    .name,
    (.repoCount // 0),
    (.path // "")
  ] | @tsv']]
  for _, row in ipairs(lines(cmd)) do
    if row[1] ~= nil and row[1] ~= "" then
      entries[#entries + 1] = {
        Text = row[2],
        Subtext = (row[3] or "0") .. " repos",
        Value = row[1],
      }
    end
  end
  return entries
end
