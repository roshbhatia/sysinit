{
  values,
  ...
}:
{
  launchd.user.agents.chromadb = {
    serviceConfig = {
      ProgramArguments = [
        "/Users/${values.user.username}/.local/bin/chroma"
        "run"
        "--port"
        "9786"
        "--path"
        "/Users/${values.user.username}/Documents/chromadb-data"
        "--log-path"
        "/Users/${values.user.username}/Documents/chromadb-log"
      ];
      WorkingDirectory = "/Users/${values.user.username}/Documents";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/chromadb.log";
      StandardErrorPath = "/tmp/chromadb.error.log";
    };
  };
}
