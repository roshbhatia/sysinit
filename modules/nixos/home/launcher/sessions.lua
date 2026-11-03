Name = "sessions"
NamePretty = "Sessions"
Icon = "utilities-terminal"
Action = "@ty@ session open %VALUE%"
SearchName = true
History = true

function GetEntries()
  local entries = {}
  local cmd = [[@sy@ list --json | @jq@ -r '.[] | [
    .name,
    (.repoCount // 0),
    (.path // "")
  ] | @tsv']]
  for _, row in ipairs(lines(cmd)) do
    if row[1] ~= nil and row[1] ~= "" then
      entries[#entries + 1] = {
        Text = row[1],
        Subtext = (row[2] or "0") .. " repos",
        Value = row[1],
      }
    end
  end
  return entries
end
