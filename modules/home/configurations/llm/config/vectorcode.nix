{
  config,
  ...
}:
{
  xdg.configFile."vectorcode/config.json" = {
    text = builtins.toJSON {
      db_url = "http://127.0.0.1:9876";
      db_path = "${config.home.homeDirectory}/Documents/chromadb-data";
      db_log_path = "${config.home.homeDirectory}/Documents/chromadb-log";
      embedding_function = "SentenceTransformerEmbeddingFunction";
      embedding_params = { };
      db_settings = null;
      chunk_size = 2500;
      overlap_ratio = 0.2;
      query_multiplier = -1;
      reranker = "NaiveReranker";
      reranker_params = {
        model_name_or_path = "cross-encoder/ms-marco-MiniLM-L-6-v2";
      };
      hnsw = {
        "hnsw:M" = 64;
      };
      chunk_filters = { };
      encoding = "utf8";
    };
  };
}
