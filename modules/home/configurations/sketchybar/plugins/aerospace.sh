#!/usr/bin/env bash
set -e

# Output workspace metadata only (no drawing)
# Fields: id\tname\tfocused\tdisplay\n
FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"

monitor_ids=( $(aerospace list-monitors --json | jq -r '.[]."monitor-id"') )
for display in "${monitor_ids[@]}"; do
  for sid in $(aerospace list-workspaces --monitor "$display"); do
    space_name=$(aerospace list-workspaces --all | awk -v s="$sid" '$1==s {for(i=2;i<=NF;++i) printf $i " "; print ""}' | sed 's/ *$//')
    [ -z "$space_name" ] && space_name="$sid"
    focused=0
    if [[ "$sid" == "$FOCUSED_WORKSPACE" ]]; then
      focused=1
    fi
    echo -e "$sid\t$space_name\t$focused\t$display"
  done
done

