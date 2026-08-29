---
artifact: outputs/venue-matrix.md
schema-version: 1
trip: data-architecture-demo
writer: hub
lifecycle: rebuilt-each-synthesis
provenance: derived
publish: bound
generated: 2026-08-29
---

# Venue Matrix

> **Illustrative, sanitized example. Not a real trip.**

Built by the hub **before** the day-by-day itinerary, not after. Its job is to make
the deduplication rule checkable before any day is written.

**This file is where `ven-<token>` is minted.** C11 is a table-shaped entry-bearing
class, so its entry marker is a **declared key column** rather than a fenced block —
the same form `outputs/event-status.md` already uses for `Event ID`. The prose-shaped
research classes (C5, C7, C9, C18) carry the key they read from here in an
`artifact-entry` fence instead. Two marker forms, one rule: the marker carries the
entity key and nothing else.

**The rule:** no venue appears as an anchor on one day and an alternative on another,
and no venue exceeds **2 appearances** in total.

| Venue key | Venue | Day(s) | Role(s) | Appearances |
|-----------|-------|--------|---------|-------------|
| `ven-7b2e` | Livraria Lello | May 14 (Thu) | A | 1 |
| `ven-c41a` | Jardins do Palácio de Cristal | May 14 (Thu) | A | 1 |
| `ven-93d7` | Serralves | May 15 (Fri) | A | 1 |
| `ven-2f68` | Mercado do Bolhão | May 15 (Fri) | A | 1 |
| `ven-e05b` | Miradouro da Vitória | May 16 (Sat) | A | 1 |
| `ven-8a34` | Base Porto | May 16 (Sat) | A | 1 |
| `ven-1d9f` | Casa do Livro | May 16 (Sat) | Alt | 1 |
| `ven-6c72` | Ribeira riverside | May 17 (Sun) | A | 1 |
| `ven-b5e0` | Café Majestic | May 14 (Thu), May 16 (Sat) | Alt, Alt | **2** ! |

`A` = anchor · `Alt` = alternative · `!` = at the two-appearance cap.

**`ven-b5e0` is the row that exercises the rule rather than merely obeying it.** It
appears twice, which is the cap and not a violation, and it holds the **same** role
both times. The forbidden shape is not "twice" — it is anchor on one day and
alternative on another, which would quietly demote a venue the plan had already
promised. Every other venue here sits at one appearance, so without this row the
matrix would be consistent with a rule that simply said "never repeat a venue", and
would not distinguish that rule from the one the engine actually applies.

**The key is opaque and placement-independent**, for the same reason the Event ID is
day-independent: it is the cross-artifact join key. A key spelling the display name
would lie the moment a venue is renamed, and a key encoding the day would lie the
moment the hub moved it — and the whole point of a join key is that neither of those
edits touches it.

**Bailout coverage.** `HC-2` requires any outdoor block that would sit in direct sun
between 13:00 and 16:00 to carry a named indoor bailout. `ven-b5e0` is the bailout for
both such blocks, which is why it is the venue that reaches the cap.
