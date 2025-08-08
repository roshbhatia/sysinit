{
  config,
  lib,
  values,
  pkgs,
  utils,
  ...
}:

let
  importWith = module: attrs: import ./${module} attrs;
  modulesWithArgs = [
    {
      name = "hammerspoon";
      attrs = { inherit pkgs; };
    }
    {
      name = "atuin";
      attrs = { inherit lib values; };
    }
    {
      name = "bat";
      attrs = {
        inherit
          lib
          pkgs
          values
          utils
          ;
      };
    }
    {
      name = "colima";
      attrs = { inherit lib pkgs; };
    }
    {
      name = "git";
      attrs = { inherit lib values; };
    }
    {
      name = "helix";
      attrs = {
        inherit
          config
          lib
          pkgs
          values
          ;
      };
    }
    {
      name = "k9s";
      attrs = { inherit lib values; };
    }
    {
      name = "macchina";
      attrs = { inherit config pkgs; };
    }
    {
      name = "neovim";
      attrs = { inherit config lib values; };
    }
    {
      name = "nu";
      attrs = {
        inherit
          config
          lib
          values
          pkgs
          ;
      };
    }
    {
      name = "omp";
      attrs = { inherit lib values; };
    }
    {
      name = "treesitter";
      attrs = { inherit config lib pkgs; };
    }
    {
      name = "utils";
      attrs = { inherit pkgs; };
    }
    {
      name = "wezterm";
      attrs = { inherit config lib values; };
    }
    {
      name = "zsh";
      attrs = {
        inherit
          config
          lib
          values
          pkgs
          ;
      };
    }
  ];
in
{
  imports = [
    ./direnv
    ./llm
    ./vivid
  ]
  ++ map (m: importWith m.name m.attrs) modulesWithArgs;
}
