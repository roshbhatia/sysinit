return {
  {
    "letieu/jira.nvim",
    cmd = "Jira",
    enabled = function()
      return os.getenv("JIRA_BASE_URL") and os.getenv("JIRA_EMAIL") and os.getenv("JIRA_TOKEN")
    end,
    opts = {
      jira = {
        base = os.getenv("JIRA_BASE_URL"),
        email = os.getenv("JIRA_EMAIL"),
        token = os.getenv("JIRA_TOKEN"),
        type = "pat",
        api_version = "3",
        limit = 200,
      },
    },
  },
}
