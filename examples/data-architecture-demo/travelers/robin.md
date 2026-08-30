---
artifact: travelers/<traveler>.md
schema-version: 1
trip: data-architecture-demo
writer: human
lifecycle: persist-mutable
provenance: human
publish: internal
---

# Your Travel Profile — Robin

> **Illustrative, sanitized example. Not a real person.** No real personal detail
> appears in this file.

**Same section and field surface as `alex.md`, in the template's own order.** The
two profiles differ in their answers and in nothing else — which is the point: the
label surface is what `agents/00-enrichment.md` parses, so it does not vary by
traveller. `alex.md` carries the full statement of why; this file does not restate
it.

---

## About you

- ⭐ **Name:** Robin
- **Relationship:** —
- **Party:** —

---

## Destination leanings

- **Would love:** —
- **Rather skip:** —
- ⭐ **Trip vibe:** —

---

## Dates & availability

- ⭐ **Can travel:** —
- **Blackout:** —
- **Trip length:** —

---

## Getting there & back

- ⭐ **Leaving from:** the group's origin
- **Arrive / leave:** same as the group
- **Journey comfort:** —
- **Passport:** —

---

## Where you stay

- ⭐ **Lodging style:** —
- **Rooming:** —

---

## Budget appetite

- ⭐ **Comfort range:** —
- **Splurge appetite:** —

---

## Needs — the must-haves

- **Category:** Mobility
- ⭐ **Specific:** Stairs are hard; level or lift approaches only.
- **Applies to:** `Hard Constraints → "HC-1 — No stair-heavy routing on any day"`

- **Category:** Rest
- ⭐ **Specific:** One genuinely slow afternoon in the middle of the trip.
- **Applies to:**

**The second block is the case the `Applies to:` line exists to make visible.** A
need with **no** governing trip-level constraint is legitimate — it binds this
traveller only — and the template's own rule is to keep the line and leave it
blank rather than to invent a constraint in `trip-context.md` to point at. Per
`reference/data-architecture.md`, agreement between needs-compliance and
constraint-compliance is **forward-only**, so this row yields a needs-compliance
row with no constraint Critical behind it.

An empty `Applies to:` and an em dash are not the same answer anywhere else in this
file: the interview guide leaves this one field label-only by instruction, because
the reconciler links it rather than the traveller.

---

## Desires — what you want

- ⭐ **Desire:** See contemporary art
- **Priority tier:** anchor
- **Recurrence:** one-off
- **Theme tag(s):** art, indoor
- **Overlap:**

- **Desire:** Walk along the river
- **Priority tier:** wish
- **Recurrence:** one-off
- **Theme tag(s):** outdoor, gentle
- **Overlap:**

- **Desire:** Watch a sunset from a rooftop
- **Priority tier:** wish
- **Recurrence:** one-off
- **Theme tag(s):** views, evening
- **Overlap:**

- **Desire:** Hear live fado
- **Priority tier:** nice-to-have
- **Recurrence:** one-off
- **Theme tag(s):** music, evening
- **Overlap:**

**Two things this desire set is here to demonstrate.** *Watch a sunset from a
rooftop* is Alex's anchor and Robin's wish — one placement can satisfy both, which
is what the overlap signal is for, and the signal is computed in
`outputs/traveler-model.md` rather than asserted here. *Hear live fado* is
**deliberately left uncovered** by this fixture's itinerary, so
`outputs/satisfaction-metrics.md` carries a desire-coverage row reading `not
covered`. A fixture in which every boolean lands on the same side demonstrates only
one of its two values.

---

## Travel style & pace

- ⭐ **Pace:** —
- **Day rhythm:** —
- **Novelty vs comfort:** —
- **Planning style:** —

---

## Interests & tastes

- ⭐ **Interests:** —
- **Cuisine appetite:** —
- **Been here before?:** —
- **Already done:** —

---

## People dynamics & togetherness

- **Group time:** —
- **Split off with:** —
- **Solo, I'd:** —
- **Whole-group moments:** —

---

## Anything else

- **Special occasion?:** —

—
