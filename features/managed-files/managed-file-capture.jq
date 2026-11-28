def nixkey:
  if test("^[a-zA-Z_][a-zA-Z0-9_'-]*$") then . else tojson end;

def nixval($indent):
  ($indent + "  ") as $nested_indent
  | if type == "object" then
      if length == 0 then "{ }"
      else "{\n" + ([to_entries[] | $nested_indent + (.key | nixkey) + " = " + (.value | nixval($nested_indent)) + ";"] | join("\n")) + "\n" + $indent + "}"
      end
    elif type == "array" then
      if length == 0 then "[ ]"
      else "[\n" + ([.[] | $nested_indent + nixval($nested_indent)] | join("\n")) + "\n" + $indent + "]"
      end
    elif type == "string" then tojson
    elif type == "boolean" then (if . then "true" else "false" end)
    elif type == null then "null"
    else tostring
    end;

def changed_tree($base; $live):
  reduce ($live | keys_unsorted[]) as $key ({};
    if ($base | has($key) | not) then .
    elif $base[$key] == $live[$key] then .
    elif (($base[$key] | type) == "object") and (($live[$key] | type) == "object") then
      (changed_tree($base[$key]; $live[$key])) as $subtree
      | if ($subtree | length) == 0 then . else .[$key] = $subtree end
    else .[$key] = $live[$key]
    end);

def added_tree($base; $live):
  reduce ($live | keys_unsorted[]) as $key ({};
    if ($base | has($key) | not) then .[$key] = $live[$key]
    elif (($base[$key] | type) == "object") and (($live[$key] | type) == "object") then
      (added_tree($base[$key]; $live[$key])) as $subtree
      | if ($subtree | length) == 0 then . else .[$key] = $subtree end
    else .
    end);

.[0] as $base
| .[1] as $live
| if $mode == "changed" then changed_tree($base; $live) else added_tree($base; $live) end
| if length == 0 then "" else nixval("") end
