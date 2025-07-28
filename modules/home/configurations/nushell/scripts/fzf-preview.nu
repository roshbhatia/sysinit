# Nushell version of fzf-preview (zsh/bin/fzf-preview)
def main [target: string] {
  let target = ($target | str replace "~" $nu.home-path)
  let center = 0
  if not ($target | path exists) {
    let match = ($target | parse --regex '^(?<file>.+):(?<line>\d+)(:(?<col>\d+))? *$')
    if ($match | length) > 0 {
      let target = $match.0.file
      let center = ($match.0.line | into int)
    }
  }
  let type = (^file --brief --dereference --mime -- $target | str trim)
  if ($target | path type) == 'dir' {
    eza --color=always --icons=always -1 $target
  } else if ($type | str starts-with 'image/') {
    wezterm imgcat $target
  } else {
    bat --style=numbers -r 0:30 --color=always --pager=never -- $target
  }
}

# Usage: fzf-preview.nu <file>
if ($env.FZF_PREVIEW_TARGET? | is-empty | not) {
  main $env.FZF_PREVIEW_TARGET
}
