---
artifact: outputs/scheduling-framework.md
schema-version: 1
trip: data-architecture-demo
writer: scheduling
lifecycle: accumulate-append
provenance: researched
publish: internal
generated: 2026-08-29
---

# Scheduling Framework — Porto

> **Illustrative, sanitized example. Not a real trip.**

**Depth: tier 2 — the migrated-shape minimum.** See `README.md` § *Depth*.

## Day shape (2026-08-29)

| Day | Shape | Blocks |
|---|---|---|
| May 14 (Thu) | arrival, half day — usable from ~14:00 | 2 |
| May 15 (Fri) | full day | 2 |
| May 16 (Sat) | full day, deliberately slowed | 2 + 1 alternative |
| May 17 (Sun) | departure, half day — depart ~13:00 | 1 |

## Signal emitted to the hub

This spoke **produces** its objective as a signal and does not synthesize. The hub
consumes and reconciles it exactly once, alongside the routing and experience
signals; nothing here writes into the hub's synthesis flow.

- **Attention signal:** Saturday carries the trip's only slowed afternoon. It is
  placed on a full day rather than on the arrival or departure day, because a
  partial day is already short and slowing it would remove the day rather than pace
  it.
- **Constraint interaction:** no outdoor block is scheduled between 13:00 and 16:00
  on any day. On May 14 and May 16 that is the binding reason for the placement
  time; on May 15 and May 17 no outdoor block falls in the window at all, which is
  why `outputs/satisfaction-metrics.md` grades Alex's heat need on two days rather
  than four.
