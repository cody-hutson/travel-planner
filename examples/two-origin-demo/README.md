# Two-Origin Demo — per-traveler planning days

A minimal worked example for `### Per-Traveler Planning Days [DERIVED]`. It exists to
show the derivation on a party that does **not** all leave from one place or land at
one time — and to exercise all three basis values on **both** axes, window and origin.

Not a real trip. Placeholder people, a placeholder destination, a placeholder window.
Companion to `examples/ideation-demo/`, which is minimal in the same way.

## The trip

- Destination: Lisbon, Portugal (WEST, UTC+1)
- Trip-level window: Thu Apr 9 – Wed Apr 15
- Anchor origin `Origin A` (the `## Logistics` Outbound/Return legs): Austin (AUS),
  CDT (UTC-5)
- Second origin `Origin B`: Manchester (MAN), BST (UTC+1) — recorded at the trip
  level under `## Logistics` → `### Additional origins`, with
  `Departing travelers: Pat`. Its legs are not booked yet, which is why Pat's
  window basis is `UNKNOWN` while their origin basis is `ASSERTED-DIFFERENT` —
  origin and timing are independent.

## What each traveler wrote

Straight from their own `travelers/<name>.md` → `## Getting there & back`.
These fields live only in the traveler files — `trip-context.md` copies no
`Leaving from:` or `Arrive / leave:` value. Where a traveler names an origin the
trip adopts, the **trip level** records that origin as its own fact under
`### Additional origins` and attaches the traveler to it by roster name only; the
profile field stays the cross-check, never the source.

| Traveler | `Leaving from:` | `Arrive / leave:` |
|----------|-----------------|-------------------|
| Jordan | `Austin (AUS)` | `same as the group` |
| Riley | `whatever the group flies out of` | `—` *(skipped)* |
| Pat | `Manchester` | `—` *(skipped)* |
| Sam | `—` *(skipped)* | `arriving a day early, heading home Sunday rather than Wednesday` |

## What that classifies to

| Traveler | Window basis | Origin basis | Why |
|----------|--------------|--------------|-----|
| Jordan | `ASSERTED-SAME` | `ASSERTED-DIFFERENT` | Said they are on the group's booking; named their origin, which happens to be the group's |
| Riley | `UNKNOWN` | `ASSERTED-SAME` | Said nothing about timing — **unknown**; elected the group's origin without naming it, so it **tracks** if the group rebooks |
| Pat | `UNKNOWN` | `ASSERTED-DIFFERENT` | Said nothing about timing — **unknown, not "same as the group"**; named a different origin |
| Sam | `ASSERTED-DIFFERENT` | `UNKNOWN` | Stated their own arrival and departure; never said where from |

Pat is the case the old field shape could not express: a traveler flying from a
different continent whose blank timing field would once have read as "on the group's
flights" — producing a jet-lag delta computed from Austin (+6 hours) for someone
leaving Manchester, who in these dates crosses **no** time zones at all. Nothing in
the old shape could say that was wrong.

Jordan and Riley are the pair that shows what the Origin basis column is *for*. Both
leave from Austin, and the derived departure city is identical — but Jordan named it
and Riley did not, so Jordan's is pinned and Riley's tracks. If the group rebooked out
of Dallas, Riley would move with it and Jordan would not. Classification follows what
a traveler bound their answer to, never whether two values happen to agree today.

Dates are 2026: Wed Apr 8, Thu Apr 9, Sun Apr 12, Wed Apr 15 — days of week verified.
Manchester is on BST (UTC+1) and Lisbon on WEST (UTC+1) across this window, so Pat's
delta is genuinely zero; Austin is on CDT (UTC-5), so the group's is +6.

See `trip-context.md` in this folder for the derived result.
