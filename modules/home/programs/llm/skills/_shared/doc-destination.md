## Step 0: pick the destination

Decide where the doc lands before writing a line:

```
if the Notion MCP is connected AND usable AND this is a work task
  -> create the page in the private/personal portion of the Notion workspace
elif the project is roshbhatia / ross-corp, OR Notion is unavailable
  -> write a markdown file under .sysinit/  (gitignored scratch space)
```

Name local files `.sysinit/{{kind}}-<slug>.md`. State the destination to the user
before creating anything outward-facing (a Notion page is outward-facing).
