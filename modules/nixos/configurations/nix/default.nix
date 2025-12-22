{
  values,
  ...
}:

{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
      trusted-users = [
        "root"
        "@wheel"
        values.user.username
      ];
      builders-use-substitutes = true;
      max-jobs = "auto";
      cores = 0;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Apply nix configuration from repo
  environment.etc."nix/nix.conf.d/custom.conf".source = ../../../../nix.custom.conf;
}
