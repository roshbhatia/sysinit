_:
let
  serenaConfigYaml = ''
    # whether to open a graphical window with Serena's logs.
    # This is mainly supported on Windows and (partly) on Linux; not available on macOS.
    # If you want to see the logs in a web browser, use the `web_dashboard` option instead.
    # Limitations: doesn't seem to work with the community version of Claude Desktop for Linux
    # Might also cause problems with some MCP clients - if you have any issues, try disabling this
    gui_log_window: false

    # whether to open the Serena web dashboard (which will be accessible through your web browser) that
    # shows Serena's current session logs - as an alternative to the GUI log window which
    # is supported on all platforms.
    web_dashboard: true

    # whether to open a browser window with the web dashboard when Serena starts (provided that web_dashboard
    # is enabled). If set to False, you can still open the dashboard manually by navigating to
    # http://localhost:24282/dashboard/ in your web browser (24282 = 0x5EDA, SErena DAshboard).
    web_dashboard_open_on_launch: false

    # the minimum log level for the GUI log window and the dashboard (10 = debug, 20 = info, 30 = warning, 40 = error)
    log_level: 20

    # whether to trace the communication between Serena and the language servers.
    # This is useful for debugging language server issues.
    trace_lsp_communication: false

    # timeout, in seconds, after which tool executions are terminated
    tool_timeout: 240

    # list of tools to be globally excluded
    excluded_tools: []

    # list of optional tools to be included
    included_optional_tools: []

    # Used as default for tools where the apply method has a default maximal answer length.
    # Even though the value of the max_answer_chars can be changed when calling the tool, it may make sense to adjust this default
    # through the global configuration.
    default_max_tool_answer_chars: 150000

    # whether to record tool usage statistics, they will be shown in the web dashboard if recording is active.
    record_tool_usage_stats: false

    # Only relevant if `record_tool_usage` is True; the name of the token count estimator to use for tool usage statistics.
    # See the `RegisteredTokenCountEstimator` enum for available options.
    token_count_estimator: TIKTOKEN_GPT4O

    # MANAGED BY SERENA, KEEP AT THE BOTTOM OF THE YAML AND DON'T EDIT WITHOUT NEED
    # The list of registered projects.
    # To add a project, within a chat, simply ask Serena to "activate the project /path/to/project" or,
    # if the project was previously added, "activate the project <project name>".
    # By default, the project's name will be the name of the directory containing the project, but you may change it
    # by editing the (auto-generated) project configuration file `/path/project/project/.serena/project.yml` file.
    # If you want to maintain full control of the project configuration, create the project.yml file manually and then
    # instruct Serena to activate the project by its path for first-time activation.
    # NOTE: Make sure there are no name collisions in the names of registered projects.
    projects: []
  '';
in
{
  home.file = {
    ".serena/serena_config.yml".text = serenaConfigYaml;
  };
}
