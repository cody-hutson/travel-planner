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

**Entry marker.** C9 is prose-shaped and its entity is the **Leg**, so its marker key
is `leg: leg-<token>` — a third entity key across the entry-bearing set, alongside C5
/ C7 / C18's `venue:` and C8's `day:`.

## Legs (2026-08-29)

Single origin, one group booking, so there is exactly one outbound and one return leg
and no per-traveller variation to reconcile. This is the shape
`examples/two-origin-demo/` exists to contrast: there the party does not share one
booking, and the leg set is not derivable from the trip level alone.

### Outbound — Origin to OPO

```artifact-entry
leg: leg-04a1
```

May 14 (Thu). Arrival ~13:00; accommodation from 14:00, which is what makes the
arrival day a half day rather than a full one.

### Return — OPO to Origin

```artifact-entry
leg: leg-9f3c
```

May 17 (Sun). Afternoon flight, depart accommodation ~13:00 — which is what leaves
Sunday a usable morning and lets `EV-2f77` be placed at all.

## In-destination movement

All eight placements are reached on foot or by lift-served transit, which is the
`HC-1` requirement. No leg on this trip requires a stepped approach, so no placement
was excluded on mobility grounds. **In-destination movement carries no leg keys here**
— the two keyed legs are the booked flights. A walked approach between two placements
is not a Leg entity in this model, and minting tokens for walks would put entities in
the file that the model does not define.

## Signal emitted to the hub

- **Geographic routing signal:** the four days cluster tightly enough that no day
  requires a cross-city transfer between blocks. Routing therefore does not compete
  with desire-coverage on this trip, so the hub's reconciliation had no conflict to
  resolve — a property of this fixture, not a general result.
