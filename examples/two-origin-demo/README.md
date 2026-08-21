# Two-Origin Demo — per-traveler planning days

A minimal worked example for `### Per-Traveler Planning Days [DERIVED]`. It exists to
show the derivation on a party that does **not** all leave from one place or land at
one time — and to exercise all three basis values.

Not a real trip. Placeholder people, a placeholder destination, a placeholder window.
Companion to `examples/ideation-demo/`, which is minimal in the same way.

## The trip

- Destination: Lisbon, Portugal (WEST, UTC+1)
- Trip-level window: Thu Apr 9 – Wed Apr 15
- Trip-level origin (the `## Logistics` legs): Austin (AUS), CDT (UTC-5)

## What each traveler wrote

Straight from their own `travelers/<name>.md` → `## Getting there & back`.
These lines live only in the traveler files; nothing below is copied into
`trip-context.md`.

| Traveler | `Leaving from:` | `Arrive / leave:` |
|----------|-----------------|-------------------|
| Jordan | `Austin (AUS)` | `same as the group` |
| Pat | `Manchester` | `—` *(skipped)* |
| Sam | `—` *(skipped)* | `arriving a day early, heading home Sunday rather than Wednesday` |

## What that classifies to

| Traveler | Window basis | Origin basis | Why |
|----------|--------------|--------------|-----|
| Jordan | `ASSERTED-SAME` | `ASSERTED-DIFFERENT` | Said they are on the group's booking; named their origin, which happens to be the group's |
| Pat | `UNKNOWN` | `ASSERTED-DIFFERENT` | Said nothing about timing — **unknown, not "same as the group"**; named a different origin |
| Sam | `ASSERTED-DIFFERENT` | `UNKNOWN` | Stated their own arrival and departure; never said where from |

Pat is the case the old field shape could not express: a traveler flying from a
different continent whose blank timing field would once have read as "on the group's
flights" — producing a jet-lag delta computed from Austin (+6 hours) for someone
leaving Manchester, who in these dates crosses **no** time zones at all. Nothing in
the old shape could say that was wrong.

Dates are 2026: Wed Apr 8, Thu Apr 9, Sun Apr 12, Wed Apr 15 — days of week verified.
Manchester is on BST (UTC+1) and Lisbon on WEST (UTC+1) across this window, so Pat's
delta is genuinely zero; Austin is on CDT (UTC-5), so the group's is +6.

See `trip-context.md` in this folder for the derived result.
