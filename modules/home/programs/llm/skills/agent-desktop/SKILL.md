---
name: agent-desktop
description: Operate native desktop apps through the OS accessibility tree with the agent-desktop CLI or its MCP server. Use for computer use on a desktop GUI, such as clicking, typing, reading UI state, menus, and windows. Use Playwright or Firefox DevTools for web pages instead.
---

# Desktop computer use

`agent-desktop` is the primary computer-use tool on this machine. It reads an
app's accessibility tree and acts on element refs, so it needs no screenshots
or pixel matching. The installed binary carries guides that match its version;
load them instead of relying on memory.

## First use in a session

```sh
agent-desktop status
agent-desktop skills get desktop
agent-desktop skills get platform
```

`status` reports permissions. On macOS, Accessibility and Screen Recording
belong to the app that launches the CLI, such as WezTerm. A `denied` state
needs the owner: report `agent-desktop permissions --guide` and stop. Do not
try to change privacy settings yourself.

<example>
<bad>`status` shows Accessibility denied, so drive System Settings to grant it.</bad>
<good>`status` shows Accessibility denied. Report it and ask the owner to run `agent-desktop permissions --guide`.</good>
</example>

## Choose the surface

- Native app on this desktop: `agent-desktop`, through the CLI or the
  `agent-desktop` MCP server.
- Web page: the Playwright or Firefox DevTools MCP servers.

<example>
<bad>Open Firefox with agent-desktop to read a web page's DOM.</bad>
<good>Read the web page through the Firefox DevTools MCP server; use agent-desktop for the native Finder dialog it opens.</good>
</example>

## Input mode

The owner has approved headed mode on this machine. The MCP server runs with
the global `--headed` flag; pass `--headed` on CLI calls too. Headed mode allows
physical input (pointer, focus, synthesized keys) where no semantic path
exists, so prefer ref actions and use raw coordinates only when no ref fits.
Physical input moves the owner's real pointer and focus: say what you are about
to do before a sequence of physical actions.

<example>
<bad>Click `--xy 640,400` without a snapshot because coordinates are allowed.</bad>
<good>Take a snapshot, click the button's ref, and use `--xy` only for a canvas that exposes no ref.</good>
</example>

Snapshots, screenshots, and clipboard reads can contain private desktop
content. Keep them out of commits, logs, and uploads.
