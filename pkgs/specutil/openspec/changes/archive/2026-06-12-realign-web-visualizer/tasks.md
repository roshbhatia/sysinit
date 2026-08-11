## 1. Realign the web-interaction spec

- [x] 1.1 Write the `web-interaction` delta: ADD "Static CDN-backed visualizer",
      "Lifecycle styling and progress", "Readable per-change document"; MODIFY
      "Graceful empty and edgeless states"; REMOVE "Self-contained interactive
      graph", "Lifecycle styling and focus highlighting", "Clickable ticket drawer",
      "Node search" (each with Reason/Migration).
- [x] 1.2 Validate the change: `openspec validate realign-web-visualizer` reports no
      errors.

## 2. Confirm the implementation already matches the realigned spec

- [x] 2.1 Confirm the binary stays network-free: `go test ./internal/guard/`
      (`TestNoNetworkImportsInBinary`) passes.
- [x] 2.2 Confirm the CDN trust boundary holds: `TestWebRuntimeIsPinnedCDN` passes
      (old vendored bundles gone; every CDN tag pinned + SRI + `crossorigin` +
      `onerror`; data feeds inlined).
- [x] 2.3 Confirm the full suite is green: `go test ./...`, `go vet ./...`,
      `gofmt -l internal/` clean.

## 3. Reconcile the in-flight specutil-core delta (follow-up)

- [x] 3.1 Update `specutil-core`'s `web-visualizer` delta so it no longer mandates
      Mermaid rendering or full offline operation, matching the shipped behavior,
      before `specutil-core` is archived — preventing the contradiction from
      re-merging. (Also realigned its proposal/design/tasks references.)
