---
artifact: outputs/transport-brief.md
schema-version: 1
trip: data-architecture-demo
writer: transport
lifecycle: accumulate-append
provenance: researched
publish: internal
generated: 2026-08-29
---

# Transport Brief — Porto

> **Illustrative, sanitized example. Not a real trip.** Transport details are
> illustrative.

**Depth: tier 2 — the migrated-shape minimum.** See `README.md` § *Depth*.

## Legs (2026-08-29)

Single origin, one group booking, so there is exactly one outbound and one return
leg and no per-traveller variation to reconcile. This is the shape
`examples/two-origin-demo/` exists to contrast.

| Leg | Date | Note |
|---|---|---|
| Origin → OPO | May 14 (Thu) | arrival ~13:00, accommodation from 14:00 |
| OPO → Origin | May 17 (Sun) | afternoon flight, depart accommodation ~13:00 |

## In-destination movement

All eight placements are reached on foot or by lift-served transit, which is the
`HC-1` requirement. No leg on this trip requires a stepped approach, so no placement
was excluded on mobility grounds.

## Signal emitted to the hub

- **Geographic routing signal:** the four days cluster tightly enough that no day
  requires a cross-city transfer between blocks. Routing therefore does not compete
  with desire-coverage on this trip, so the hub's reconciliation had no conflict to
  resolve — a property of this fixture, not a general result.
