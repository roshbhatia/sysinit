{
  lib,
  pkgs,
  system,
  ...
}:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = lib.mkDefault (system == "x86_64-linux");
    extraPackages = with pkgs; [
      libva
    ];
    extraPackages32 =
      if system == "x86_64-linux" then
        with pkgs.driversi686Linux;
        [
          libva
        ]
      else
        [ ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };
}
