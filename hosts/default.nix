{
  ...
}:
let
  common = {
    username = "rshnbhatia";

    git = {
      name = "Roshan Bhatia";
      email = "rshnbhatia@gmail.com";
      username = "roshbhatia";
    };
  };
in
{
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;

    values = {
      inherit (common) git;
      user.username = common.username;
      hostname = "lv426";
      environment = {
        LIMA_INSTANCE = "nostromo";
      };
    };
  };

  nostromo = {
    system = "aarch64-linux";
    platform = "linux";
    isLima = true;
    inherit (common) username;

    values = {
      inherit (common) git;
      user.username = common.username;
      hostname = "nostromo";
      isLima = true;
    };
  };
}
