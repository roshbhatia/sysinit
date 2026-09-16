def rank:
  if . == "waiting" or . == "blocked" then 3
  elif . == "working" then 2
  elif . == "done" then 1 else 0 end;
def attention_rank:
  if . == "waiting" or . == "blocked" then 2
  elif . == "done" then 1 else 0 end;
($live | map({key: (.pane_id | tostring), value: .}) | from_entries) as $panes
| map(select((.pane | type) == "string" or (.pane | type) == "number")
    | .pane |= tostring
    | select($panes[.pane] != null)
    | .session = (if (.session | type) == "string" and .session != "" then .session
        else ($panes[.pane].workspace // "default") end)
    | .status = (if (.status | type) == "string" then (if .status == "blocked" then "waiting" else .status end) else "unknown" end)
    | .repo = (if (.repo | type) == "string" then .repo else "" end)
    | .since = (.since | tonumber? // 0)) as $records
| ($records | group_by(.session) | map({
    name: .[0].session,
    status: (max_by(.status | rank) | .status),
    rank: (map(.status | rank) | max),
    repo: ([.[].repo | select(length > 0)] | first // ""),
    panes: length,
    blocked: ([.[] | select(.status == "waiting" or .status == "blocked")] | length),
    attention: ([.[] | select((.status | attention_rank) > 0)] | length),
    attention_status: (max_by(.status | attention_rank) | .status),
    attention_rank: (map(.status | attention_rank) | max),
    since: ([.[].since | select(. > 0)] | min // null)
  })) as $active
| ($known | split("\n") | map(select(length > 0)) | unique) as $names
| ($names - ($active | map(.name)) | map({name: ., status: null, rank: 0,
    repo: "", panes: 0, blocked: 0, attention: 0, attention_rank: 0,
    attention_status: null, since: null})) as $idle
| {selected: (if $selected == null then null else
      ([$records[] | select($panes[.pane].is_active == true) | .session] | first // $selected) end),
    selection_state: $selstate, discovery_state: "fresh",
    sessions: (($active + $idle) | sort_by(-.rank, .name))}
