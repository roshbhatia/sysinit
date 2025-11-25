{
  ...
}:
let
  cursorConfig = builtins.toJSON {
    version = 1;
    permissions = {
      allow = [
        "Shell(ls)"
        "Shell(rg)"
        "Shell(head)"
        "Shell(git show)"
        "Shell(wc)"
        "Shell(grep)"
        "Shell(cd)"
        "Shell(make)"
        "Shell(git diff)"
        "Shell(git status)"
        "Shell(tail)"
        "Shell(which)"
        "Shell(cat)"
        "Shell(pwd)"
        "Shell(mkdir)"
        "Shell(kubectl get)"
        "Shell(kubectl describe)"
        "Shell(kubectl logs)"
        "Shell(kubectl explain)"
        "Shell(kubectl api-resources)"
        "Shell(kubectl api-versions)"
        "Shell(kubectl cluster-info)"
        "Shell(kubectl version)"
        "Shell(kubectl config view)"
        "Shell(kubectl config get-contexts)"
        "Shell(kubectl config current-context)"
        "Shell(kubectl top)"
        "Shell(crossplane --version)"
        "Shell(crossplane xpkg)"
        "Shell(crossplane beta trace)"
        "Shell(crossplane beta validate)"
      ];
      deny = [ ];
    };
    editor = {
      vimMode = true;
    };
    network = {
      useHttp1ForAgent = true;
    };
  };
in
{
  xdg.configFile."cursor/cli-config.json" = {
    text = cursorConfig;
    force = true;
  };
  home.file.".cursor/cli-config.json" = {
    text = cursorConfig;
    force = true;
  };
}
