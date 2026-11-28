def haspath($path):
  if ($path | length) == 0 then true
  elif type != "object" then false
  elif has($path[0]) then (.[$path[0]] | haspath($path[1:]))
  else false
  end;

.[0] as $result
| .[1] as $declared
| .[2] as $live
| reduce $enforced_paths[] as $path ($result;
    if ($declared | haspath($path)) then setpath($path; $declared | getpath($path))
    elif ($live | haspath($path)) then setpath($path; $live | getpath($path))
    else .
    end)
