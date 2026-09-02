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

**This file does not mint `ven-<token>`; it carries keys that already exist.** The
mint point is the hub's **first enumeration of the venue set, before it writes either
reference file** (`agents/05-hub-planner.md` § *Pre-Work: Build Reference Artifacts
First*). Pre-Work writes `outputs/links-reference.md` first and this file second, so
by the time this table is built the keys have been minted and both reference files
carry them from their first write. C11 is a table-shaped entry-bearing class, so its
entry marker is a **declared key column** rather than a fenced block — the same form
`outputs/event-status.md` already uses for `Event ID`. The prose-shaped research
classes (C5, C7, C9, C18) carry their own key in an `artifact-entry` fence instead,
and carry it **one pass late**. Two marker forms, one rule: the marker carries the
entity key — and, in the fenced form only, one optional `cost:` line, which
§ 4.5.1 admits and this table's declared-key-column form does not. A table already
has columns, so a cost belonging to a table-shaped class is a column of it.

**The rule:** no venue appears as an anchor on one day and an alternative on another,
and no venue exceeds **2 appearances** in total.

| Venue key | Venue | Day(s) | Role(s) | Appearances |
|-----------|-------|--------|---------|-------------|
| `ven-7b2e` | Livraria Lello | May 14 (Thu) | A | 1 |
| `ven-c41a` | Jardins do Palácio de Cristal | May 14 (Thu) | A | 1 |
| `ven-3c17` | Tasca do Bairro | May 14 (Thu) | A | 1 |
| `ven-2f68` | Mercado do Bolhão | May 15 (Fri) | A | 1 |
| `ven-93d7` | Serralves | May 15 (Fri) | A | 1 |
| `ven-a90d` | Casa de Pasto Central | May 16 (Sat) | A | 1 |
| `ven-e05b` | Miradouro da Vitória | May 16 (Sat) | A | 1 |
| `ven-8a34` | Base Porto | May 16 (Sat) | A | 1 |
| `ven-1d9f` | Casa do Livro | May 16 (Sat) | Alt | 1 |
| `ven-5e6b` | Padaria São Bento | May 17 (Sun) | A | 1 |
| `ven-6c72` | Ribeira riverside | May 17 (Sun) | A | 1 |
| `ven-b5e0` | Café Majestic | May 14 (Thu), May 16 (Sat) | B, B | **2** ! |

`A` = anchor · `Alt` = alternative · `B` = bailout · `!` = at the two-appearance cap.

**The role vocabulary is three values, not two, and the third one is load-bearing.**
`agents/05-hub-planner.md` § *Pre-Work Output 2: venue-matrix.md* declares the cells as
`A = anchor, Alt = alternative, B = bailout, blank = not used`. A matrix that spent
`Alt` on a bailout would collapse two roles the emitter keeps apart, and the
deduplication rule is **role-sensitive** — its forbidden shape is *anchor on one day
and alternative on another* — so the collapse would make the very split the rule
forbids unobservable on the file that exists to make it checkable. The hub's own
status discipline reads the same three values: an `option` event is placed **as Alt or
B, never as A**, which is a distinction a two-value vocabulary cannot carry.

**`ven-b5e0` is the row that exercises the rule rather than merely obeying it.** It
appears twice, which is the cap and not a violation, and it holds the **same** role
both times — `B` on Thursday and `B` on Saturday, the standing indoor escape for the
two outdoor blocks. The forbidden shape is not "twice" — it is anchor on one day and
alternative on another, which would quietly demote a venue the plan had already
promised. Every other venue here sits at one appearance, so without this row the
matrix would be consistent with a rule that simply said "never repeat a venue", and
would not distinguish that rule from the one the engine actually applies.

**All three roles are present, which is what makes the rule readable.** `ven-1d9f` is
the trip's only `Alt` — the Saturday alternative, carried in
`outputs/event-status.md` as the `option`. `ven-b5e0` is the only `B`. Every other row
is `A`. A matrix carrying only `A` and `Alt` would leave a reader unable to tell
whether a bailout is an alternative by another name; these two rows say it is not.

**The key is opaque and placement-independent**, for the same reason the Event ID is
day-independent: it is the cross-artifact join key. A key spelling the display name
would lie the moment a venue is renamed, and a key encoding the day would lie the
moment the hub moved it — and the whole point of a join key is that neither of those
edits touches it.

**Bailout coverage.** `HC-2` requires an outdoor block that would sit in direct sun
between 13:00 and 16:00 to be moved, shaded, **or** given a named indoor bailout.
`ven-b5e0` is the named bailout on the two days carrying an afternoon outdoor block —
Thu 14 and Sat 16 — which is why it is the venue that reaches the cap. **Neither block
now sits inside the window**: both were placed clear of it, and the bailout is carried
anyway rather than treated as discharged by the timing alone.

**Three rows here were minted at this pass and their research markers have not caught
up.** `ven-3c17`, `ven-a90d` and `ven-5e6b` are the anchor-meal venues appended to
`outputs/activities-list.md` on this same pass, whose `artifact-entry` markers still
read `venue: unminted`. The hub matched those mentions to these places by its
five-rung identity procedure, not by reading a key off the research file — which is
what `reference/data-architecture.md` § 3.3 means by *the key is a convergence
optimisation and never the join basis*. The cap above is counted over keys, and a
still-`unminted` mention would count as **its own** venue if one remained: the cap
over-counts rather than passing silently on a merge nobody made.
