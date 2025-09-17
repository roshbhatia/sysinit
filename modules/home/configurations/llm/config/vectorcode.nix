{
  config,
  ...
}:
{
  xdg.configFile."vectorcode/config.json5" = {
    source = builtins.toFile "config.json5" (
      builtins.toJSON {
        db_url = "http://127.0.0.1:9876";
        db_path = "${config.home.homeDirectory}/Documents/chromadb/";
        db_log_path = "${config.home.homeDirectory}/Documents/chromadb/";
        db_settings = {
          chroma_server_host = "localhost";
          chroma_server_http_port = 9876;
          persist_directory = "${config.home.homeDirectory}/Documents/chromadb";
        };
      }
    );
  };
}
