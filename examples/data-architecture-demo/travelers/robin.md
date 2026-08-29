---
artifact: travelers/<traveler>.md
schema-version: 1
trip: data-architecture-demo
writer: human
lifecycle: persist-mutable
provenance: human
publish: internal
---

# Traveler — Robin

> **Illustrative, sanitized example. Not a real person.** No real personal detail
> appears in this file.

## Getting there & back

- **Leaving from:** the group's origin
- **Arrive / leave:** same as the group

## Needs

| Need | Category | Applies to |
|------|----------|-----------|
| Stairs are hard; level or lift approaches only | mobility | `HC-1` |
| One genuinely slow afternoon in the middle of the trip | rest | — (no trip-level constraint; a preference bound, recorded as a need at this traveller's own scope) |

The second row is the case the `Applies to:` column exists to make visible. A need
with **no** governing trip-level constraint is legitimate — it binds this traveller
only — and it is recorded with an explicit `—` rather than by inventing a constraint
in `trip-context.md` to point at. Per `reference/data-architecture.md`, agreement
between needs-compliance and constraint-compliance is **forward-only**, so this row
yields a needs-compliance row with no constraint Critical behind it.

## Desires

| Desire | Tier | Recurrence | Themes |
|--------|------|-----------|--------|
| See contemporary art | anchor | one-off | art, indoor |
| Walk along the river | wish | one-off | outdoor, gentle |
| Watch a sunset from a rooftop | wish | one-off | views, evening |
| Hear live fado | nice-to-have | one-off | music, evening |

**Desire overlap.** *Watch a sunset from a rooftop* is Alex's anchor and Robin's
wish — one event can satisfy both, which is what the overlap signal is for.

*Hear live fado* is **deliberately left uncovered** by this fixture's itinerary, so
`outputs/satisfaction-metrics.md` carries a desire-coverage row reading `not
covered`. A fixture in which every boolean lands on the same side demonstrates only
one of its two values.
