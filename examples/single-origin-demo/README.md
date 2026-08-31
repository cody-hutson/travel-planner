# Single-Origin Demo — the collapsed per-traveler block

A minimal worked example of the **single-origin collapse** in
`### Per-Traveler Planning Days [DERIVED]`. It exists to show what the block renders
as when the collapse precondition holds: the per-traveler table is **deleted** and
replaced by one `- **All travelers:**` line carrying a warrant census.

Not a real trip. Placeholder people, a placeholder destination, a placeholder window.
Companion to `examples/two-origin-demo/`, which is minimal in the same way and shows
the same block **uncollapsed**.

## The trip

- Destination: Seville, Spain (CEST, UTC+2)
- Trip-level window: Thu Jun 11 – Mon Jun 15
- Origin: Denver (DEN), MDT (UTC-6) — the only origin. `### Additional origins` is
  absent from `trip-context.md` rather than empty, because the block exists only
  where a second origin does.
- One group booking; all three travelers are on it.

## What each traveler wrote

Straight from their own `travelers/<name>.md` → `## Getting there & back`.
These fields live only in the traveler files — `trip-context.md` copies no
`Leaving from:` or `Arrive / leave:` value.

| Traveler | `Leaving from:` | `Arrive / leave:` |
|----------|-----------------|-------------------|
| Mira | `whatever the group flies out of` | `same as the group` |
| Ravi | `whatever the group books` | `on the group booking` |
| Tess | `—` *(skipped)* | `—` *(skipped)* |

## What that classifies to

| Traveler | Window basis | Origin basis | Why |
|----------|--------------|--------------|-----|
| Mira | `ASSERTED-SAME` | `ASSERTED-SAME` | Said they are on whatever the group books, on both axes — **elected**, so both **track** the trip level |
| Ravi | `ASSERTED-SAME` | `ASSERTED-SAME` | Same shape as Mira, in different words. Neither named a city or a date |
| Tess | `UNKNOWN` | `UNKNOWN` | Answered neither field — **unknown, not "same as the group"** |

Every basis is `ASSERTED-SAME` or `UNKNOWN`, and that is the collapse precondition
in `templates/trip-context.template.md`. No traveler pinned anything, so the group
has one window and one origin and there is nothing for a per-traveler row to say that
the trip-level block does not already say.

## Why the table is absent

Under the rule the table is **deleted**, not left in place with three identical rows.
`trip-context.md` renders exactly this in place of it:

`- **All travelers:** trip-level window applies — no traveler states a different arrival, departure, or origin. 2 asserted, 1 assumed.`

The census is what the deletion is not allowed to lose. `2 asserted` is Mira and Ravi,
who each said they were on the group's arrangements. `1 assumed` is Tess, who
*inherits* the trip-level window rather than having agreed to it — so anything derived
from Tess's presence on a given day is an assumption and has to be named as one. Both
travelers end up with the same dates; only one of them consented to them, and the two
counts are how a reader still knows that after the table is gone.

**What would break the collapse.** A traveler who *named* an origin — even DEN, this
trip's own — would classify `ASSERTED-DIFFERENT` and **pin** it. The precondition
would fail and the full table would return. That is the distinction
`examples/two-origin-demo/` is built around: Jordan names Austin and is pinned, Riley
elects the group's origin and tracks, and both leave from the same city. Here nobody
named one, so all three bases track: rebook this group out of another city and every
traveler moves with it.

For the contrast case, `examples/data-architecture-demo/` meets this same precondition
and renders the table anyway, on purpose, to expose the per-traveler basis values that
the collapse hides. Its `### Per-Traveler Planning Days [DERIVED]` section says so in
place, so the two fixtures do not read as a contradiction.

Dates are 2026: Wed Jun 10, Thu Jun 11, Fri Jun 12, Sat Jun 13, Sun Jun 14, Mon Jun 15
— days of week verified. Denver is on MDT (UTC-6) and Seville on CEST (UTC+2) across
this window, so the group's delta is +8 hours, eastbound.

See [`trip-context.md`](trip-context.md) in this folder for the derived result.
