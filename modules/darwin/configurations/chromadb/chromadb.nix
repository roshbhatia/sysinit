{
  lib,
  pkgs,
  values,
  ...
}:

{
  launchd.user.agents.chromadb = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.python3}/bin/python3"
        "-m"
        "chroma"
        "run"
        "--host"
        "localhost"
        "--port"
        "9786"
        "--path"
        "/Users/${values.user.username}/Documents/chromadb"
      ];
      WorkingDirectory = "/Users/${values.user.username}/Documents/chromadb";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/chromadb.log";
      StandardErrorPath = "/tmp/chromadb.error.log";
    };
  };
}
