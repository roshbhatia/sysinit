// Package syncplan implements the deterministic, offline half of the sync
// story: stable item identity, the per-change lockfile (lock get/set), the
// create/update/orphan plan, and drift diffing. No network I/O happens here;
// the shipped skills drive the agent to apply a plan via MCP and record results
// back through lock set.
package syncplan

import "github.com/roshbhatia/specutil/internal/ident"

// normalize is the identity normalization shared with every other consumer of
// task handles; diff's token similarity works over the same normalized form.
func normalize(s string) string { return ident.Normalize(s) }

// Identity is the stable lock key for an item. See ident.Identity.
func Identity(phaseName, text string) string { return ident.Identity(phaseName, text) }

// ContentHash is the exact-content fingerprint stored alongside the external ID
// so plan can tell an unchanged item (skip) from an edited one (update).
func ContentHash(text string) string { return ident.ContentHash(text) }
