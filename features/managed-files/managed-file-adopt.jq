.[0] as $live
| .[1] as $declared
| ($live | delpaths($retired_paths))
| (. * $declared)
