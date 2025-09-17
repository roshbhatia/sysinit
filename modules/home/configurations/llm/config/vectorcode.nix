{
  config,
  ...
}:
{
  xdg.configFile."vectorcode/config.json5" = {
    source = builtins.toFile "config.json5" (
      builtins.toJSON {
        db_url = "http://127.0.0.1:9876";
        db_path = "${config.home.homeDirectory}/Documents/chromadb-data";
        db_log_path = "${config.home.homeDirectory}/Documents/chromadb-log";
      }
    );
  };
}
