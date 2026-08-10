{ ... }:
{
  # ast-grep, playwright and basic-memory are reached through agentgateway,
  # which already folds them in as stdio targets. Declaring them here too made
  # every harness launch a second copy of each: duplicate tool schemas in the
  # prompt, and two basic-memory processes racing the same note store.
  sysinit.llm.mcp.additionalServers = { };
}
