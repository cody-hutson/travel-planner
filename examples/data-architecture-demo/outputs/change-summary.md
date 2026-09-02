---
artifact: outputs/change-summary.md
schema-version: 1
trip: data-architecture-demo
writer: hub
lifecycle: accumulate-append
provenance: derived
publish: internal
generated: 2026-08-29
status: pending
---

# Change Summary

> **Illustrative, sanitized example. Not a real trip.**

**Depth: tier 1 — no tracked instance of this class existed anywhere before this
fixture.** See `README.md` § *Depth*. It therefore carries enough content to exercise
the class's own rules: two dated sections, so the surviving-entry property is visible
rather than asserted; all three difference buckets that this trip's history actually
produced; and the one per-class field, `status`.

**`status: pending` is the fixture's whole point, read against the section below it.**
The **2026-08-29** entry has not been decided, so the artifact-level answer to *is a
change pending for this trip?* is yes — while the **2026-08-28** entry, decided and
long since acted on, is still sitting in the same file, untouched. That is
`accumulate-append` doing the one job it was chosen for. Under `rebuilt-each-synthesis`
the older entry would be gone; under `persist-mutable` the pending one would have been
overwritten by the pass that produced it.

**Every row below is derived from a key, and the keys come from two files only** —
`outputs/event-status.md` (`Event ID`) and `outputs/venue-matrix.md` (`ven-<token>`).
`outputs/final-itinerary.md` is **not** diffed and carries neither key by design, so
nothing below is read from it.

**The *What* column is a label; the *Before* and *After* columns are the comparison.**
`What` holds the display name a reader knows the thing by and is never matched on — the
`Key` column is what joins. `Before` and `After` hold the **placement**, and for an
`Event ID` that placement is `(day, time)`: both fields come from `outputs/event-status.md`,
which carries `Day` and `Time` as columns. The `14:00` and the `16:30` in the MOVED row
below are therefore compared values, not decoration. Read them as prose lifted out of the
itinerary and the row would be unreproducible, because the itinerary is the one file this
class is forbidden to diff.

**The bucket is the first column, and that is not cosmetic.** A table opening with a
`ven-<token>` against a display string is the *declared key column* form
`outputs/venue-matrix.md` and `outputs/links-reference.md` use, and it is read as a
venue-identity binding. This file records a change; it is not a second place where a
key is bound to a name.

## 2026-08-28 — first synthesis

**In plain language:** the first pass placed seven events across the four days. There
was no prior plan to compare against, so every key is new.

| Bucket | Key | What | Before | After |
|--------|-----|------|--------|-------|
| ADDED | `evt-3f9a` | Livraria Lello timed entry | — | May 14 (Thu) 15:00 · `locked` |
| ADDED | `evt-8c21` | Jardins do Palácio de Cristal | — | May 14 (Thu) 17:00 · `planned` |
| ADDED | `evt-b47e` | Serralves — contemporary art | — | May 15 (Fri) 15:00 · `planned` |
| ADDED | `evt-c052` | Miradouro da Vitória | — | May 16 (Sat) 14:00 · `planned` |
| ADDED | `evt-5ab8` | Base Porto — rooftop at sunset | — | May 16 (Sat) 19:30 · `locked` |
| ADDED | `evt-9e34` | Casa do Livro — bar | — | May 16 (Sat) · `option` |
| ADDED | `evt-2f77` | Riverside walk, Ribeira to the bridge | — | May 17 (Sun) 09:30 · `planned` |

**A first synthesis is not a no-op.** The before-map is empty, so the difference is the
whole plan and the rule emits. This is worth seeing once: the no-op condition is *the
difference is empty*, never *this is the first run*.

## 2026-08-29 — proposed change

**In plain language:** Saturday afternoon slowed down — the viewpoint moved from 14:00
to 16:30 — and the activities spoke's second pass put one anchor meal on each day.

| Bucket | Key | What | Before | After |
|--------|-----|------|--------|-------|
| MOVED | `evt-c052` | Miradouro da Vitória | May 16 (Sat) 14:00 | May 16 (Sat) 16:30 |
| ADDED | `evt-7a05` | Tasca do Bairro — dinner | — | May 14 (Thu) 20:00 · `planned` |
| ADDED | `evt-1d60` | Mercado do Bolhão — market-hall lunch | — | May 15 (Fri) 12:30 · `firmed` |
| ADDED | `evt-6e2b` | Casa de Pasto Central — lunch | — | May 16 (Sat) 13:00 · `planned` |
| ADDED | `evt-d1c8` | Padaria São Bento — breakfast | — | May 17 (Sun) 08:30 · `planned` |

**`evt-c052` MOVED rather than DROPPED-and-ADDED, and the Event ID is why.** The hub
mints the ID on first placement and it is day-independent, so re-timing the event
leaves the key untouched and the difference reads as one row instead of two. A summary
built over display titles would have reported a drop and an unrelated addition, and
the group would have read it as two changes. The same holds one level down: **time is an
attribute compared *within* the matched key, never part of it.** Fold `16:30` into the
identity and `evt-c052` at 14:00 and `evt-c052` at 16:30 are two keys, and this one row
becomes the same misleading pair by a different route.

**And this row is the only reason the 2026-08-29 section exists at all.** Its `Day` did not
change, its venue's role in `outputs/venue-matrix.md` did not change, and its `Status` is
`planned` on both sides — so `ADDED`, `DROPPED` and `STATUS-CHANGED` are all silent about
it. `MOVED` sees it because the placement it compares for an `Event ID` is `(day, time)`
and `outputs/event-status.md` carries `Time` as a column. Take that column away and the
four buckets are empty for this event; the anchor-meal rows are all that remain, and a pass
that had moved the group's Saturday afternoon by two and a half hours would have said so
nowhere.

**One removal on this pass is not in the table, and its absence is the artifact's
coverage boundary rather than an omission.** The supporting block that stood after the
viewpoint in `outputs/final-itinerary-v1.md` carried no `Event ID` and no
`ven-<token>` — it was prose in a day body. A keyed difference cannot see an unkeyed
entry, and the alternative, diffing the itinerary text, is the prose diffing this
class exists to replace. What reaches the group is what the model keys.

**The DROPPED and STATUS-CHANGED buckets are empty on both passes**, and they are named
here rather than left out. A bucket omitted because it happened to be empty reads to
the next author as a bucket that does not exist.
