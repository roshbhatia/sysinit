let
  registry = import ../../home/programs/llm/harnesses/registry.nix;
  harnessAliases = builtins.listToAttrs (map (h: h.shellAlias) (builtins.attrValues registry));
  fullAccessAliases = builtins.listToAttrs (
    map (h: {
      name = "${h.command}-full";
      value = h.shellAlias.value;
    }) (builtins.attrValues registry)
  );
  commonAliases =
    harnessAliases
    // fullAccessAliases
    // {
      cat = "bat -pp";
      f = "y";
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
    sudo = "sudo -E";
  };
in
{
  inherit commonAliases posixAliases;
  allAliases = commonAliases // posixAliases;
}
