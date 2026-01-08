# Load user-specific extras and secrets
# Similar to zsh extras - allows user customizations without modifying config

let extras_dir = (($env.XDG_CONFIG_HOME? // $"($env.HOME)/.config") | path join "nushell" "extras")

if ($extras_dir | path exists) {
  let extra_files = (ls $extras_dir | where type == "file" and (name ends-with ".nu" or name ends-with ".sh") | get name)
  
  for file in $extra_files {
    try {
      source $file
    } catch {|e|
      print $"Warning: Failed to source ($file): ($e.msg)"
    }
  }
}

# Load secrets if present
let secrets_file = $"($env.HOME)/.nusecrets"
if ($secrets_file | path exists) {
  try {
    source $secrets_file
  } catch {|e|
    print $"Warning: Failed to source secrets: ($e.msg)"
  }
}
