let
  commonAliases = {
    cat = "bat -pp";
    f = "yazi";
    kk = "k9s";
    ll = "eza --icons=always -l -a";
    lt = "eza --tree";
    # nh darwin switch with --impure so builtins.pathExists resolves local extras paths
    nhs = "nh darwin switch -- --impure";
    nhb = "nh darwin build -- --impure";
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
