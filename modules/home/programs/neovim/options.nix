{ lib, config, ... }:

{
  options.sysinit.neovim = {
    configPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/programs/neovim/config";
      description = ''
        Directory that ~/.config/nvim symlinks to. It must be inside a checkout of
        THIS repository, and it must be writable: lazy.nvim writes lazy-lock.json
        into the config root, and the point of the symlink is that a config edit
        needs no switch.

        Deliberately NOT derived from `programs.nh.flake`. That option names the
        flake which defines the host, and a consuming flake
        overrides it to its own checkout, which does not carry this repository's
        module tree. Following it would make activation fail on exactly the host
        that consumes this repository rather than being it.

        A host whose sysinit checkout is somewhere else overrides this.
      '';
    };
  };
}
