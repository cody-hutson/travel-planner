---
artifact: outputs/final-itinerary-v<N>.md
schema-version: 1
trip: data-architecture-demo
writer: hub
lifecycle: versioned
provenance: derived
publish: internal
generated: 2026-08-28
---

# Final Itinerary — Porto, May 14–17 2026 (v1, superseded)

> **Illustrative, sanitized example. Not a real trip.**

**`artifact:` carries the class string `outputs/final-itinerary-v<N>.md`, not this
file's own name.** C16 is a class whose members are all named `…-v<N>.md` for some
N; the angle-bracketed segment is part of the class as § 1.1 spells it. A value of
`outputs/final-itinerary-v1.md` here would be finding `A5` — the file would be
naming its own path where the field's domain is one value per class row.

**C16 is a separate class from C15, not a variant of it**, and the two differ on
more than age: C15 is `publish: bound` and C16 is `publish: internal`. A superseded
version is not publish-bound — it is kept so the decision history survives, and
shipping it to a reader alongside the current plan would be a way to act on a plan
nobody is on any more.

This is the pass **before** the Saturday patch. It is preserved verbatim; the hub
does not edit a frozen sibling.

## May 16 (Sat) — as it stood in v1

| Time | Event | ID | Status |
|------|-------|----|--------|
| 14:00 | Miradouro da Vitória | `EV-c052` | `planned` |
| 16:30 | *(a second afternoon block, since dropped)* | — | — |
| 19:30 | Base Porto — rooftop at sunset | `EV-5ab8` | `locked` |

Two things this version shows that the current one cannot:

1. **`EV-c052` kept its ID across the change.** The same event moved from 14:00 to
   16:30 in v2. Because the ID is opaque and day-independent, the move is a
   re-timing rather than a delete-and-mint, and `outputs/event-status.md` needed one
   cell changed rather than a row replaced.
2. **The 14:00 placement sat inside the `HC-2` window** — an outdoor viewpoint
   between 13:00 and 16:00. Moving it to 16:30 is why the current pass shows
   Saturday's heat row as a `pass`.

The other three days are unchanged from v1 to v2 and are not restated here; a frozen
sibling preserves the version, and re-listing days the patch never touched would put
a second copy of them in the repository for the next reader to reconcile.
