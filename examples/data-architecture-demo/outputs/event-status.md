---
artifact: outputs/event-status.md
schema-version: 1
trip: data-architecture-demo
writer: hub
lifecycle: persist-mutable
provenance: derived
publish: bound
generated: 2026-08-29
---

# Event Status

> **Illustrative, sanitized example. Not a real trip.**

The structured per-event source of truth for the scheduler, hub and validator.
**`persist-mutable`** — updated in place, survives every re-synthesis, never rebuilt
from scratch and never versioned. A re-synthesis *reads* this file; it does not
overwrite it.

**Entry marker: a declared key column.** C13 is table-shaped, so `Event ID` is the
marker — the form the model cites this very file as the precedent for. `Venue key` is
a **foreign** key beside it, read from `outputs/venue-matrix.md`; the entity this file
keys is the Event, not the venue.

**Event ID is opaque and day-independent.** The hub mints it on first placement and it
is the cross-run join key, so it must not encode the day — which is exactly what lets
the Saturday patch below move an event without minting a new identity.

**"Needs booking" is derived, not stored:** `planned` **and** `requires booking? =
yes`. `firmed`, `locked` and `option` therefore never read as needing a booking, even
when an `option` carries `requires booking? = yes` as a bookable backup — that flag
takes effect only on promotion to `planned`.

| Event ID | Venue key | Event | Day | Status | Requires booking? | Needs booking (derived) |
|----------|-----------|-------|-----|--------|-------------------|-------------------------|
| `EV-3f9a` | `ven-7b2e` | Livraria Lello timed entry | May 14 (Thu) | `locked` | yes | no — booked |
| `EV-8c21` | `ven-c41a` | Jardins do Palácio de Cristal | May 14 (Thu) | `planned` | no | no |
| `EV-b47e` | `ven-93d7` | Serralves — contemporary art | May 15 (Fri) | `planned` | yes | **yes** |
| `EV-1d60` | `ven-2f68` | Mercado do Bolhão | May 15 (Fri) | `firmed` | no | no |
| `EV-c052` | `ven-e05b` | Miradouro da Vitória | May 16 (Sat) | `planned` | no | no |
| `EV-5ab8` | `ven-8a34` | Base Porto — rooftop at sunset | May 16 (Sat) | `locked` | yes | no — booked |
| `EV-9e34` | `ven-1d9f` | Casa do Livro — bar | May 16 (Sat) | `option` | yes | no — an alternative, never a primary slot |
| `EV-2f77` | `ven-6c72` | Riverside walk, Ribeira to the bridge | May 17 (Sun) | `planned` | no | no |

**The derived column is a truth table, and every row is checkable against it.** Only
`EV-b47e` is `planned` **and** `requires booking? = yes`, so only it reads **yes**.
`EV-9e34` is the row that makes the rule visible rather than merely satisfied: it
carries `requires booking? = yes` and still reads **no**, because an `option` is not a
primary slot.

**All four status values are present**, which is the point of the table: `planned` is
the only one iteration and resequencing change freely, `locked` and `firmed` are
preserved unless the user names them, and `option` is never auto-promoted.

**One `planned` needs-booking event remains** (`EV-b47e`), so "all events locked" is
false for this trip. That is the reading the phrase is defined by, and a fixture in
which nothing remained to book could not demonstrate it.

**Every `Venue key` above resolves to exactly one row in
`outputs/links-reference.md`**, the venue registry. `ven-b5e0` (Café Majestic) appears
in the registry and *not* here, which is correct: it is the standing bailout and is
never placed, so it has no event.

## What the Saturday patch did

The change recorded in `trip-context.md` § *Mode notes* moved the Saturday afternoon
later to make it slower. `EV-c052` kept its ID **and its venue key** across that move —
the ID is day-independent, so a re-timing is not a re-identification. No row was
deleted: row deletion is the single case `persist-mutable` permits, and it applies
only when an event leaves the itinerary altogether.
