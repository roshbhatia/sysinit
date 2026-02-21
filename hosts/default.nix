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
      environment = {
        LIMA_INSTANCE = "nostromo";
      };
    };
  };

  nostromo = {
    system = "aarch64-linux";
    platform = "linux";
    lima = true;
    inherit (common) username;

    values = {
      inherit (common) git;
    };
  };
}
