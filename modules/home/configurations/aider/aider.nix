{
  lib,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.file.".aider.conf.yml" = {
    source = ./aider.conf.yml;
    force = true;
  };

  home.activation.aider = activation.mkPackageManager {
    name = "uv";
    basePackages = [
      "aider-chat@lates"
    ];
    additionalPackages = [ ];
    executableArguments = [
      "tool"
      "install"
      "--python"
      "python3.12"
      "--with"
      "pip"
    ];
    executableName = "uv";
  };
}

