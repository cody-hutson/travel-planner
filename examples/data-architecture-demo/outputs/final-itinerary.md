---
artifact: outputs/final-itinerary.md
schema-version: 1
trip: data-architecture-demo
writer: hub
lifecycle: versioned
provenance: derived
publish: bound
generated: 2026-08-29
---

# Final Itinerary — Porto, May 14–17 2026 (v2)

> **Illustrative, sanitized example. Not a real trip.**

**`versioned`:** this file is *replaced* on each synthesis rather than appended, and
the version it replaced is preserved beside it as
`outputs/final-itinerary-v1.md` — an instance of the separate frozen-sibling class
C16. This is v2; v1 is the pass before the Saturday patch.

Every placement below carries the Event ID that `outputs/event-status.md` owns and the
venue key that `outputs/venue-matrix.md` minted. The Event ID is the join key between
the two files, and it is day-independent, so a re-timing does not re-identify an
event.

## May 14 (Thu) — arrival, half day

| Time | Event | ID | Venue key | Status |
|------|-------|----|-----------|--------|
| 15:00 | Livraria Lello — timed entry | `EV-3f9a` | `ven-7b2e` | `locked` |
| 17:00 | Jardins do Palácio de Cristal | `EV-8c21` | `ven-c41a` | `planned` |

*Bailout for the gardens block:* Café Majestic (`ven-b5e0`) — indoor, level access.

## May 15 (Fri) — full day

| Time | Event | ID | Venue key | Status |
|------|-------|----|-----------|--------|
| 10:30 | Mercado do Bolhão | `EV-1d60` | `ven-2f68` | `firmed` |
| 14:00 | Serralves — contemporary art | `EV-b47e` | `ven-93d7` | `planned` |

Both venues are indoor or covered, so `HC-2` does not reach this day.

## May 16 (Sat) — full day, slowed afternoon

| Time | Event | ID | Venue key | Status |
|------|-------|----|-----------|--------|
| 16:30 | Miradouro da Vitória | `EV-c052` | `ven-e05b` | `planned` |
| 19:30 | Base Porto — rooftop at sunset | `EV-5ab8` | `ven-8a34` | `locked` |
| — | *Alternative:* Casa do Livro | `EV-9e34` | `ven-1d9f` | `option` |

**This is the day the patch changed.** In v1 the viewpoint sat at 14:00, inside the
`HC-2` window and ahead of a second afternoon block. The group asked for a slower
Saturday; the hub moved `EV-c052` to 16:30 and dropped the block that followed it.
The move kept the Event ID, and `EV-5ab8` was `locked` and so was preserved
untouched — which is the whole point of the status layer.

## May 17 (Sun) — departure, half day

| Time | Event | ID | Venue key | Status |
|------|-------|----|-----------|--------|
| 09:30 | Riverside walk, Ribeira to the bridge | `EV-2f77` | `ven-6c72` | `planned` |

Depart accommodation by ~13:00.

## Booking checklist

Derived from `outputs/event-status.md`, never authored here — an event needs booking
when it is `planned` **and** requires one.

| Action by | Event | ID | Status |
|-----------|-------|----|--------|
| before May 15 (Fri) | Serralves — contemporary art | `EV-b47e` | `planned`, needs booking |

**One row, and that is the whole list.** `EV-3f9a` and `EV-5ab8` are `locked`,
`EV-1d60` is `firmed`, `EV-9e34` is an `option`, and the remaining three require no
booking — so none of them belongs on a checklist. Every ID here appears in
`outputs/event-status.md`; a checklist row with no status row behind it would be a
booking the plan cannot track.

---

**Depth note.** The per-venue detail a real itinerary carries — addresses, transit
legs, opening hours, booking windows, insider notes — is **not reproduced here**.
`examples/tokyo-2026/outputs/final-itinerary.md` is the worked example for that, and
this fixture exists for the migrated artifact *shape*. See `README.md` § *Depth*.
