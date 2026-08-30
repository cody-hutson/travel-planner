---
artifact: travelers/<traveler>.md
schema-version: 1
trip: data-architecture-demo
writer: human
lifecycle: persist-mutable
provenance: human
publish: internal
---

# Your Travel Profile — Alex

> **Illustrative, sanitized example. Not a real person.** No real personal detail
> appears in this file.

**The traveller's name is the title line, never a frontmatter value.** `artifact:`
carries the **class string** `travelers/<traveler>.md` exactly as
`reference/data-architecture.md` § 1.1 spells it — the same string
`templates/traveler-intake.template.md` ships. A file whose `artifact:` read
`travelers/alex.md` would be finding `A5`: the value names an instance path, and
the field's domain is one value per class row.

**This file carries the template's own section and field surface, in the template's
own order.** `agents/00-enrichment.md` parses a profile **by its stable field
labels** — `Category:` / `Specific:` / `Applies to:` for a need, `Desire:` /
`Priority tier:` / `Recurrence:` / `Theme tag(s):` / `Overlap:` for a desire, and
the nine lifecycle-facet label groups beside them — so the labels are the parse
surface and not decoration. `templates/traveler-intake.template.md` says it in
terms: *keep every field label exactly as written; do not rename, reorder, merge,
add, or drop sections or fields*, and *skipping a section never removes it from
the output* — a skipped field keeps its line and takes an em dash. A profile that
rendered its needs and desires as a markdown table would carry no label for the
reconciler to read, and everything downstream of that parse — tier, recurrence,
theme tags, overlap, the attention lens, the nightlife desire gate — would be
undemonstrated. **The em dashes below are therefore part of the shape, not filler.**

**Depth: the fixture answers only what it exercises.** Every label ships; the ones
this fixture has no fact for carry `—`, which the reconciler reads as *not
answered*, never as an answer. What is answered is exactly what
`outputs/traveler-model.md`, `outputs/satisfaction-metrics.md` and
`trip-context.md` resolve against.

---

## About you

- ⭐ **Name:** Alex
- **Relationship:** —
- **Party:** —

---

## Destination leanings

> The destination is already decided (`trip-context.md` § *Destination*), so this
> whole section is skipped. The lines stay; the answers are em dashes.

- **Would love:** —
- **Rather skip:** —
- ⭐ **Trip vibe:** —

---

## Dates & availability

> The window is fixed and booked, so this section is skipped the same way.

- ⭐ **Can travel:** —
- **Blackout:** —
- **Trip length:** —

---

## Getting there & back

- ⭐ **Leaving from:** the group's origin
- **Arrive / leave:** same as the group
- **Journey comfort:** —
- **Passport:** —

Single origin, one booking — both journey fields elect the group, so both bases
resolve `ASSERTED-SAME` in `trip-context.md` § *Per-Traveler Planning Days*.

**`Passport:` is answered with an em dash on purpose.** It is a **declared
non-publishable field** — `reference/data-architecture.md` § 5.6 carries a row for
it scoped to this very class — so a tracked, world-readable worked example is the
one place a value must not go. The label ships because the guard's field limb reads
this label from this class; the em dash is what keeps the field demonstrated and
empty at the same time.

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

> Constraints that **bound** the solution. Each links to the governing trip-level
> constraint and restates none of its text — `trip-context.md` § *Hard Constraints*
> and § *Dietary & Health* are the source of truth.

- **Category:** Heat
- ⭐ **Specific:** Afternoon sun is not tolerable for long outdoor stretches.
- **Applies to:** `Hard Constraints → "HC-2 — No outdoor block between 13:00 and 16:00 without shade"`

- **Category:** Dietary-health
- ⭐ **Specific:** No shellfish, at any group meal.
- **Applies to:** `Dietary & Health → "DH-1 — No shellfish at any group meal"`

**One block per need, and `Applies to:` carries a link rather than a copy.** The
constraint text lives once, in `trip-context.md`; this line points at it. The
`DH-1` link is the one that the plan can actually be graded against — the
itinerary places an anchor meal on every day, so
`outputs/satisfaction-metrics.md` grades this need over four days that each carry
a group meal rather than over four days that carry none.

---

## Desires — what you want

> Wants optimized **within** those bounds. Tier is a priority label, not a weight,
> and recurrence is orthogonal to it — a daily want may be an anchor, a wish, or a
> nice-to-have.

- ⭐ **Desire:** Watch a sunset from a rooftop
- **Priority tier:** anchor
- **Recurrence:** one-off
- **Theme tag(s):** views, evening
- **Overlap:**

- **Desire:** Spend real time in a good bookshop
- **Priority tier:** wish
- **Recurrence:** one-off
- **Theme tag(s):** browsing, indoor
- **Overlap:**

- **Desire:** See a working food market
- **Priority tier:** nice-to-have
- **Recurrence:** one-off
- **Theme tag(s):** local, food
- **Overlap:**

**`Overlap:` carries the label and nothing after it, on every block.** The template
says to leave it blank and the interview guide names it as one of the two fields
never asked about: the enrichment agent computes the overlap across all profiles
and writes it to `outputs/traveler-model.md` § *Desire overlap*. A traveller who
filled it in would be authoring a derived value in a source file. *Watch a sunset
from a rooftop* is in fact also held by Robin, at a lower tier — and that fact is
recorded there, not here.

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

**`Been here before?:` is `unknown` here, and that is not `never`.** It is a closed
enum — `never` / `once` / `a few times` / `know it well` — and an em-dashed field is
unanswered, so this traveller contributes no depth signal in either direction.
Reading the em dash as `never` would bias the activities agent's landmark weighting
on a fact nobody stated.

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
