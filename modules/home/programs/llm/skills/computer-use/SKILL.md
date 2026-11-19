---
name: computer-use
description: Choose and run desktop computer use with agent-desktop (accessibility tree, MCP server) or screen-relay (screenshots, browser stream, disposable Linux desktops). Use for clicking, typing, reading UI state, menus, and windows in desktop apps, in place of any harness's built-in computer-use or screenshot tools. Use Playwright or Firefox DevTools for web pages instead.
---

# Desktop computer use

Two tools are installed. Each binary carries guides that match its version;
load them instead of relying on memory.

Use these tools in every harness, in place of built-in computer use: Claude's
computer-use tool, Codex's bundled computer-use plugin, Goose's
computercontroller extension, or a harness's own screenshot capture. The owner
configured permissions, signing, and approvals for agent-desktop and
screen-relay only.

<example>
<bad>Call the harness's built-in computer-use tool to click a Finder button.</bad>
<good>Snapshot Finder with agent-desktop, or call the `agent-desktop` MCP server, and click the button's ref.</good>
</example>

| Task | Tool |
|---|---|
| Native app on this desktop: buttons, fields, menus, windows | `agent-desktop`, through the CLI or the `agent-desktop` MCP server |
| UI with no accessibility tree: canvas, game, video, remote desktop | `screen-relay` screenshots and coordinate input |
| The owner wants to watch the session live in a browser | `screen-relay` |
| Work that must not touch the owner's desktop | `screen-relay` on Linux, which starts its own X11 desktop |
| Web page DOM, network, or console | The Playwright or Firefox DevTools MCP servers |

Start with `agent-desktop` for a native app. Switch to `screen-relay` when a
snapshot shows no usable refs for the element you need, not after a single
failed action.

<example>
<bad>Take screen-relay screenshots and click coordinates to fill a System Settings form.</bad>
<good>Snapshot System Settings with agent-desktop and act on the field refs; use screen-relay only for a canvas that exposes no refs.</good>
</example>

## First use in a session

```sh
agent-desktop status
agent-desktop skills get desktop
agent-desktop skills get platform
screen-relay skills get core
```

On macOS, Accessibility and Screen Recording belong to the app that launches
the tool, such as WezTerm. When `agent-desktop status` or `screen-relay doctor`
reports a missing permission, report it and stop; the owner grants it with
`agent-desktop permissions --guide`. Do not change privacy settings yourself.

<example>
<bad>`status` shows Accessibility denied, so drive System Settings to grant it.</bad>
<good>`status` shows Accessibility denied. Report it and ask the owner to run `agent-desktop permissions --guide`.</good>
</example>

## Input mode

The owner has approved headed mode on this machine. The agent-desktop MCP
server runs with the global `--headed` flag; pass `--headed` on CLI calls too.
Headed mode allows physical input (pointer, focus, synthesized keys) where no
semantic path exists, so prefer ref actions. screen-relay input on the Mac is
always physical. Physical input moves the owner's real pointer and focus: say
what you are about to do before a sequence of physical actions.

<example>
<bad>Click `--xy 640,400` without a snapshot because coordinates are allowed.</bad>
<good>Take a snapshot, click the button's ref, and use `--xy` only for a canvas that exposes no ref.</good>
</example>

## screen-relay sessions

`screen-relay up -d` starts a session and prints a viewer link; `down` ends it.
Every input command reports only that the engine applied the input, so take a
screenshot to confirm the result. The engine listens on `127.0.0.1:8080` with
no token. Do not start it with `--public` or a non-loopback address unless the
owner asks.

Snapshots, screenshots, streams, and clipboard reads can contain private
desktop content. Keep them out of commits, logs, and uploads.
