{
  pkgs,
  ...
}:

{
  nix = {
    enable = true;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      max-jobs = "auto";
    };

    optimise = {
      automatic = true;
    };

    gc = {
      automatic = true;
      interval = {
        Weekday = 7;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 7d";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      nixpkgs-review
      nix-update
      nix-index
      nix-tree
    ];

    variables = {
      NIXPKGS_ALLOW_UNFREE = "1";
    };
  };
}

