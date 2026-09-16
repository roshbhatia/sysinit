if .selection_state == "absent" or (.selected // "") == "" then
  { text: "" }
else
  .selected as $selected
  | (
      [
        .sessions[]
        | select((.attention // 0) > 0 and .name != $selected)
      ]
      | length
    ) as $blocked
  | {
      text: (
        "󰆍 "
        + $selected
        + if $blocked > 0 then "  +" + ($blocked | tostring) else "" end
      ),
      tooltip: (
        [
          .sessions[]
          | select((.attention // 0) > 0)
          | .name + ": " + (.attention_status // "idle")
        ]
        | join("\n")
      ),
      class: .selection_state
    }
end
