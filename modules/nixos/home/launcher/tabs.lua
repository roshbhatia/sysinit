Name = "tabs"
NamePretty = "Firefox Tabs"
Icon = "firefox"
Action = "xdg-open %VALUE%"
SearchName = true
History = true

-- @menu-prelude@

function GetEntries()
  local entries = {}
  local cmd = [[@firefox-tabs@ | @jq@ -r '.[] | [
    (.title // .url),
    (.url // "")
  ] | @tsv']]
  for _, row in ipairs(lines(cmd)) do
    if row[2] ~= nil and row[2] ~= "" then
      entries[#entries + 1] = {
        Text = row[1],
        Subtext = row[2],
        Value = row[2],
      }
    end
  end
  return entries
end
