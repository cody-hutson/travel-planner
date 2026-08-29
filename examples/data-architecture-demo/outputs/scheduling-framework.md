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

**Entry marker.** C8 is prose-shaped and its entity is the **Day**, so its marker key
is `day:` carrying an ISO date — not a venue token, and not the day's ordinal. Two
entry-bearing classes, two different entity keys: the marker carries whatever key
identifies *that class's* entity, which is why the model fixes the form and each
agent prompt fixes the key.

## Day shape (2026-08-29)

### May 14 (Thu) — arrival, half day

```artifact-entry
day: 2026-05-14
```

Usable from ~14:00. Two blocks. The outdoor block is placed after 16:00, so `HC-2`
binds the placement time here.

### May 15 (Fri) — full day

```artifact-entry
day: 2026-05-15
```

Two blocks, both indoor or covered. `HC-2` does not reach this day at all — which is
why `outputs/satisfaction-metrics.md` grades Alex's heat need on two days rather than
four.

### May 16 (Sat) — full day, deliberately slowed

```artifact-entry
day: 2026-05-16
```

Two blocks plus one alternative. This is the day the patch changed: the viewpoint
moved 14:00 → 16:30 and the block after it was dropped. `HC-2` binds the new time.

### May 17 (Sun) — departure, half day

```artifact-entry
day: 2026-05-17
```

One morning block; depart accommodation ~13:00. No outdoor block in the `HC-2` window.

**The key is the ISO date, not `Day 3`.** An ordinal encodes position, and position is
exactly what a resequence changes — the same reason `outputs/event-status.md`'s Event
ID must not encode the day. A date survives a reorder; `Day 3` becomes a lie.

## Signal emitted to the hub

This spoke **produces** its objective as a signal and does not synthesize. The hub
consumes and reconciles it exactly once, alongside the routing and experience
signals; nothing here writes into the hub's synthesis flow.

- **Attention signal:** Saturday carries the trip's only slowed afternoon. It is
  placed on a full day rather than on the arrival or departure day, because a partial
  day is already short and slowing it would remove the day rather than pace it.
- **Constraint interaction:** no outdoor block is scheduled between 13:00 and 16:00 on
  any day.
