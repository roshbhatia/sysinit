{
  config,
  ...
}:
{
  xdg.configFile."vectorcode/config.json5" = {
    source = builtins.toFile "config.json5" (
      builtins.toJSON {
        db_url = "http://127.0.0.1:8000";
        embedding_function = "SentenceTransformerEmbeddingFunction";
        embedding_params = {
          model_name = "all-MiniLM-L6-v2";
        };
        db_path = "${config.home.homeDirectory}/Documents/chromadb/";
        db_log_path = "${config.home.homeDirectory}/Documents/vectorcode/";
        db_settings = {
          chroma_db_impl = "duckdb+parquet";
          chroma_server_host = "localhost";
          chroma_server_http_port = 9876;
          persist_directory = "${config.home.homeDirectory}/Documents/chromadb";
        };
        chunk_size = 2500;
        overlap_ratio = 0.2;
        query_multiplier = -1;
        reranker = "NaiveReranker";
        reranker_params = {
          model_name_or_path = "cross-encoder/ms-marco-MiniLM-L-6-v2";
        };
        hnsw = {
          M = 64;
        };
        chunk_filters = { };
        encoding = "utf8";
      }
    );
  };
}
