let
  registry = import ../../home/programs/llm/harnesses/registry.nix;
  fullAccessWords =
    h:
    let
      inherit (h.launch.fullAccess) args env;
      assignments = map (name: "${name}=${env.${name}}") (builtins.attrNames env);
    in
    (if assignments == [ ] then [ ] else [ "env" ] ++ assignments) ++ [ h.command ] ++ args;
  # A bare command keeps an env prefix, so an alias named after it cannot expand into itself.
  fullAccessCommand =
    h:
    let
      words = fullAccessWords h ++ (h.shellAlias.args or [ ]);
    in
    builtins.concatStringsSep " " (if words == [ h.command ] then [ "env" ] ++ words else words);
  harnessAliases = builtins.listToAttrs (
    map (h: {
      inherit (h.shellAlias) name;
      value = fullAccessCommand h;
    }) (builtins.attrValues registry)
  );
  fullAccessAliases = builtins.listToAttrs (
    map (h: {
      name = "${h.command}-full";
      value = fullAccessCommand h;
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
