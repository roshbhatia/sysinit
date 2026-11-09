---
name: nix-deployment
description: Build and activate a Nix-managed host, verify downstream input pins and active state, and preserve deployment roots. Use for Nix switches and deployment preparation; not for application or production service releases.
---

# Deploy a Nix host

Read the target repository's deployment instructions and inspect its active
changes. Resolve the host flake and configuration explicitly; an upstream
checkout may not define the current machine. Do not assume an environment
variable's flake points at the intended source revision.

Run `python3 scripts/host-state.py --flake <host-checkout>` from this skill's
location to inspect its Git revision, input pins, and active system. It only
reads state. Dependencies are Python and Git from the repository's Nix shell.

1. Compare the requested source revision with the consuming flake's lock. If a
   downstream pin differs, prepare the scoped lock update or explicit override
   covered by the request. Report whether it is persistent or one-time.
2. Run the owning repository's checks. Use installed `nh` to build the explicit
   host configuration into the task's named output link. Inspect its diff.
3. Activate only within existing authorization. Reuse the rooted build or the
   repository's supported `nh ... switch` command. Do not pass a store path to
   NH's Darwin installable argument; use the documented profile/activation flow
   when separate activation of an existing Darwin build is needed.
4. Run `python3 scripts/host-state.py --flake <host-checkout> --result <output-link>`.
   A mismatch with `/run/current-system` exits nonzero. Verify the changed
   installed files and native behavior as well; a matching path alone is not
   an end-to-end behavior test.
5. Report source revision, downstream pin, activation result, and remaining Git
   changes. Do not claim publication unless it was requested and verified.

Preserve unrelated prepared deployments, sessions, and recovery evidence.
Build-result symlinks are GC roots; remove only this task's temporary check roots
when finished, keeping the deployment rooted through activation.
