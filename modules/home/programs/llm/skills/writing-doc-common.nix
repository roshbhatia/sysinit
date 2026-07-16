# Shared sections for the two writing-doc-* skills. The destination decision
# and the voice binding are identical contracts; rendering them from one
# definition means they cannot drift between the design and RFC skills.
{
  destination = kind: ''
    ## Step 0 — pick the destination

    Decide where the doc lands before writing a line:

    ```
    if the Notion MCP is connected AND usable AND this is a work task
      -> create the page in the private/personal portion of the Notion workspace
    elif the project is roshbhatia / ross-corp, OR Notion is unavailable
      -> write a markdown file under .sysinit/  (gitignored scratch space)
    ```

    Name local files `.sysinit/${kind}-<slug>.md`. State the destination to the user
    before creating anything outward-facing (a Notion page is outward-facing).
  '';

  voice = ''
    ## Voice

    Load the `writing-tone` skill for the full voice contract; it is not restated
    here. The rules that bind hardest in a doc: open with an explicit in/out
    scope list; pair every claim with how it is validated, and its inverse where
    one exists; frame decision asks as `Owner:` / `By:` / `Done when:`; cut
    hedges, marketing adjectives, throat-clearing, rhetorical devices, and emojis.
  '';
}
