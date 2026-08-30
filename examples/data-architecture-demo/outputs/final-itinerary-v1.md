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

**The body shape is C15's, unchanged.** A frozen sibling is the previous pass
preserved: the hub changes exactly two frontmatter lines when it freezes one —
`artifact:` and `publish:` — and leaves everything else, frontmatter and body alike,
exactly as it was. So this file carries no Event IDs and no venue keys either, for the
reason `outputs/final-itinerary.md` states at length and this file does not repeat.

This is the pass **before** the Saturday patch. It is preserved verbatim; the hub
does not edit a frozen sibling.

---

**Day 3 — May 16 (Sat) — Saturday — as it stood in v1**
*Energy:* High | *Zone:* Centre | *Type:* Full day
*Theme:* Three things and a table booked for sunset. It is a lot for one Saturday, and
by the time you reach the rooftop you will know it.

**Anchor**
Miradouro da Vitória — 14:00 — ~45 minutes — level approach, outdoor.

**Supporting Experiences**
A second afternoon block, since dropped.

**AC Bailout** *(activate if needed)*
Café Majestic — indoor, level access.

**Alternatives**
*(Pre-researched. Hours and walk times confirmed.)*

| Option | Type | Price | Effort | Walk/Transit | Hours |
|--------|------|-------|--------|-------------|-------|
| Casa do Livro | Indoor bar | Low | Walk-in | — | — |

**Food Anchors**
- Breakfast: — *(not placed)*
- Lunch: — *(not placed)*
- Dinner: — *(not placed)*

**Transit Notes**
On foot within the centre all day: viewpoint, then the second afternoon block, then the
terrace. Three stops on one Saturday afternoon with no transfer between them — which is
the density the patch removed rather than a routing problem it solved.

**Nightlife**
Base Porto — centre — rooftop drinks at sunset — from 19:30 — lift to the terrace, table
held.

**Constraint Compliance**
`HC-1` — level approach, lift to the terrace. `HC-2` — **the 14:00 viewpoint sits
inside the 13:00–16:00 window**; the named indoor bailout is what the placement leans
on rather than the timing.

---

Three things this version shows that the current one cannot:

1. **The viewpoint kept its identity across the change.** The same event moved from
   14:00 to 16:30 in v2. Because the Event ID `outputs/event-status.md` holds for it is
   opaque and day-independent, the move is a re-timing rather than a delete-and-mint,
   and that file needed one cell changed rather than a row replaced. **The ID lives
   there and not here** — from this file a reader reaches the event by display title,
   which is the one-way join the model records as a cost.
2. **The 14:00 placement sat inside the `HC-2` window** — an outdoor viewpoint between
   13:00 and 16:00. Moving it to 16:30 is why the current pass shows Saturday's heat row
   as a `pass` on the timing rather than on the bailout alone.
3. **Every food anchor on this day was empty.** v1 placed no meal on any day of the
   trip, which is the state `agents/06-validator.md` § *Structural integrity* audits
   against — *no day is missing an anchor event or anchor meal*. The anchor meals in v2
   are what closed it, and preserving this version is what makes the difference
   readable rather than asserted.

The other three days are unchanged in shape from v1 to v2 except for the anchor meal
each of them gained, and are not restated here; a frozen sibling preserves the version,
and re-listing days the patch never restructured would put a second copy of them in the
repository for the next reader to reconcile.
