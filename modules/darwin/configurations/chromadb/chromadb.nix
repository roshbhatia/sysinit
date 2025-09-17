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
        "8000"
        "--path"
        "/Users/${values.user.username}/Documents/chromadb"
      ];
      WorkingDirectory = "/Users/${values.user.username}/Documents/chromadb";
      EnvironmentVariables = {
        CHROMA_DB_IMPL = "duckdb+parquet";
        CHROMA_SERVER_HOST = "localhost";
        CHROMA_SERVER_HTTP_PORT = "9876";
        CHROMA_PERSIST_DIRECTORY = "/Users/${values.user.username}/Documents/chromadb";
        PATH = "${lib.makeBinPath [ pkgs.python3 ]}:/usr/bin:/bin";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/chromadb.log";
      StandardErrorPath = "/tmp/chromadb.error.log";
    };
  };
}
