{ }:

{
  vet = {
    bin = "/opt/homebrew/bin/vet";
    env = "";
    installCmd = ''
      $MANAGER_CMD -f $pkg
    '';
  };
}
