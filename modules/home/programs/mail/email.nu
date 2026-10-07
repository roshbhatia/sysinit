def main [
  --personal # Open personal Gmail.
  --work # Open work Gmail.
  ...emacs_args: string # Extra Emacs arguments after --.
] {
    if $personal and $work {
        error make {msg: "Choose either --personal or --work."}
    }
    let accounts_file = "@accounts@"
    let state_file = "@state@"
    if not ($accounts_file | path exists) {
        error make {msg: "Mail accounts are not configured. See the email setup guide."}
    }
    let accounts = open $accounts_file
    let previous = if ($state_file | path exists) {
        open --raw $state_file | str trim
    } else { "" }
    let selected = if $personal { "personal" } else if $work { "work" } else if $previous in $accounts.name {
        $previous
    } else {
        $accounts | first | get name
    }
    if not ($selected in $accounts.name) {
        error make {msg: $"Mail account is not configured: ($selected)"}
    }
    $env.NOTMUCH_CONFIG = "@config@"
    $env.EMAIL_ACCOUNT = $selected
    ^"@notmuch@" new --quiet
    if $env.LAST_EXIT_CODE != 0 { exit $env.LAST_EXIT_CODE }
    exec "@emacs@" -nw -q --load "@init@" --funcall notmuch ...$emacs_args
}
