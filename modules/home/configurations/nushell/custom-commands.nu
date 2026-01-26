# Custom commands ported from zsh configuration
# Provides path management, environment inspection, directory stack, and fuzzy search utilities

# Path management - print PATH with bat formatting
export def "path print" [] {
  $env.PATH
  | split row (char esep)
  | enumerate
  | each { |it| $"($it.index + 1)\t($it.item)" }
  | to text
  | bat --style=numbers,grid --language=sh
}

# Path management - add directory to PATH
export def --env "path add" [dir: path] {
  if ($dir | path exists) {
    let expanded = ($dir | path expand)
    if $expanded not-in ($env.PATH | split row (char esep)) {
      $env.PATH = ([$expanded] ++ ($env.PATH | split row (char esep)) | str join (char esep))
      if ('SYSINIT_DEBUG' in $env) {
        print $"[PATH] Added ($expanded)"
      }
    }
  } else {
    if ('SYSINIT_DEBUG' in $env) {
      print $"[PATH] Skipped ($dir) - not a directory"
    }
  }
}

# Environment variable viewer with optional pattern filtering
export def "env print" [pattern: string = ".*"] {
  $env
  | transpose key value
  | where key =~ $pattern
  | sort-by key
  | to text
  | bat --style=numbers,grid --language=sh
}

# Directory stack management - push current directory and cd to new location
export def --env "pushd" [dir: string = "~"] {
  if ('DIR_STACK' not-in $env) {
    $env.DIR_STACK = []
  }
  $env.DIR_STACK = ([$env.PWD] ++ $env.DIR_STACK)
  cd $dir
}

# Directory stack management - pop directory from stack and cd to it
export def --env "popd" [] {
  if ('DIR_STACK' not-in $env) or (($env.DIR_STACK | length) == 0) {
    print "Directory stack empty"
    return
  }
  let prev = ($env.DIR_STACK | first)
  $env.DIR_STACK = ($env.DIR_STACK | skip 1)
  cd $prev
}

# Directory stack viewer
export def "dirs" [] {
  if ('DIR_STACK' not-in $env) {
    [$env.PWD]
  } else {
    [$env.PWD] ++ $env.DIR_STACK
  }
  | enumerate
}

# FZF-style file picker using fd and nushell's input list
export def "fzf-file" [--hidden] {
  let cmd = if $hidden {
    fd --type f --hidden --follow --exclude .git --exclude node_modules
  } else {
    fd --type f --exclude .git --exclude node_modules
  }

  $cmd | lines | input list --fuzzy
}

# FZF-style directory picker using fd and nushell's input list
export def "fzf-dir" [--hidden] {
  let cmd = if $hidden {
    fd --type d --hidden --follow --exclude .git --exclude node_modules
  } else {
    fd --type d --exclude .git --exclude node_modules
  }

  $cmd | lines | input list --fuzzy
}

# Edit file with fuzzy selection
export def --env "vf" [] {
  let file = (fzf-file)
  if ($file | is-not-empty) {
    nvim $file
  }
}

# CD with fuzzy directory selection
export def --env "cdf" [] {
  let dir = (fzf-dir)
  if ($dir | is-not-empty) {
    cd $dir
  }
}

# Git branch switcher with fuzzy search
export def --env "gsw" [] {
  git branch --all
  | lines
  | each { |line| $line | str trim | str replace '* ' '' | str replace 'remotes/origin/' '' }
  | uniq
  | input list --fuzzy "Select branch:"
  | str trim
  | if ($in | is-not-empty) {
      git switch $in
    }
}
