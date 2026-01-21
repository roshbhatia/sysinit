return {
  {
    "letieu/jira.nvim",
    cmd = "Jira",
    enabled = not not (
        os.getenv("JIRA_BASE_URL")
        and os.getenv("JIRA_EMAIL")
        and os.getenv("JIRA_TOKEN")
        and os.getenv("JIRA_AUTH_TYPE")
      ),
    opts = {
      jira = {
        base = os.getenv("JIRA_BASE_URL"),
        email = os.getenv("JIRA_EMAIL"),
        token = os.getenv("JIRA_TOKEN"),
        type = os.getenv("JIRA_AUTH_TYPE"),
        api_version = 3,
        limit = 200,
      },
    },
  },
}
