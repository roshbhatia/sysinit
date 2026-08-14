let
  commonAliases = {
    # One keystroke, because ask is written at the end of a pipe rather than at the start
    # of a line: `cat log | _ classify this`.
    "_" = "ask";
    c = "claude --dangerously-skip-permissions";
    cat = "bat -pp";
    f = "yazi";
    kk = "k9s";
    ll = "eza --icons=always -l -a";
    lt = "eza --tree";
    org = "nvim ~/org/notes";
    sg = "ast-grep";
    tf = "tofu";
    tree = "eza --tree --icons=never";
    v = "nvim";
  };

  posixAliases = {
    diff = "diff --color";
    find = "fd";
    grep = "rg -s --color=auto";
    sudo = "sudo -E";
  };
in
{
  inherit commonAliases posixAliases;
  allAliases = commonAliases // posixAliases;
}
