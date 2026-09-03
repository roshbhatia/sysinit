def show($value):
  ($value | tojson) as $rendered
  | if ($rendered | length) > 160 then ($rendered[0:160] + " ...") else $rendered end;

def merge3($path; $base; $live; $declared):
  if $live == $declared then $declared
  elif $live == $base then $declared
  elif $declared == $base then $live
  elif (($base | type) == "object") and (($live | type) == "object") and (($declared | type) == "object") then
    ([($base | keys_unsorted[]), ($live | keys_unsorted[]), ($declared | keys_unsorted[])] | unique) as $keys
    | reduce $keys[] as $key (
        {};
        ($base | has($key)) as $base_has_key
        | ($live | has($key)) as $live_has_key
        | ($declared | has($key)) as $declared_has_key
        | ($path + [$key]) as $next_path
        | if $base_has_key and $live_has_key and $declared_has_key then
            .[$key] = merge3($next_path; $base[$key]; $live[$key]; $declared[$key])
          elif $base_has_key and $live_has_key and ($declared_has_key | not) then
            if $live[$key] == $base[$key] then . else .[$key] = $live[$key] end
          elif $base_has_key and ($live_has_key | not) and $declared_has_key then
            if $declared[$key] == $base[$key] then .
            else error("conflict at ." + ($next_path | join(".")) + ": the live file deleted this key and the Nix content changed it.\n  base: " + show($base[$key]) + "\n  live: (absent)\n  nix:  " + show($declared[$key])) end
          elif ($base_has_key | not) and $live_has_key and $declared_has_key then
            if $live[$key] == $declared[$key] then .[$key] = $declared[$key]
            # recurse so independent nested additions merge before enforced paths are restored
            elif (($live[$key] | type) == "object") and (($declared[$key] | type) == "object") then
              .[$key] = merge3($next_path; {}; $live[$key]; $declared[$key])
            else error("conflict at ." + ($next_path | join(".")) + ": the live file and the Nix content each added a different value.\n  base: (absent)\n  live: " + show($live[$key]) + "\n  nix:  " + show($declared[$key])) end
          elif ($base_has_key | not) and $live_has_key and ($declared_has_key | not) then
            .[$key] = $live[$key]
          elif ($base_has_key | not) and ($live_has_key | not) and $declared_has_key then
            .[$key] = $declared[$key]
          else . end
      )
  else
    error("conflict at ." + ($path | join(".")) + ": the base, the live file, and the Nix content all differ.\n  base: " + show($base) + "\n  live: " + show($live) + "\n  nix:  " + show($declared))
  end;

merge3([]; .[0]; .[1]; .[2])
