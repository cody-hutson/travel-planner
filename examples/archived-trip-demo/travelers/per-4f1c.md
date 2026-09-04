---
artifact: travelers/<traveler>.md
schema-version: 1
trip: archived-trip-demo
writer: human
lifecycle: persist-mutable
provenance: human
publish: internal
---

# Your Travel Profile — per-4f1c

> **Illustrative, sanitized example. Not a real person.** No real personal detail
> appears in this file.

**This is the first-party erasure subject: a filed profile that also referenced a
durable person record.** The reference is what makes the tombstone legible after the
fact. `reference/adr/ADR-012-people-library.md` distinguishes a tombstoned bearer from a
dangling one **structurally, before any store read**: a tombstone has *no reference
field left to dangle*, while a dangling reference has a well-formed field that fails to
resolve. So the erased form of this file carries no `person:` key at all, and a reader
meeting it reports `TOMBSTONED` rather than a defect.

---

## About you

- ⭐ **Name:** per-4f1c
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

**The need survives the erasure and that is deliberate.** Erasure removes a person's
identifying values, not the constraint structure the plan was built on. Emptying this
link — or the `Applies to:` roster in `trip-context.md` it points at — would turn a
concluded plan into one that grades as compliant while no longer carrying the need it
was built around, which is the milestone's own named risk.

---

## Desires — what you want

- ⭐ **Desire:** See one thing properly rather than three quickly
- **Priority tier:** anchor
- **Recurrence:** one-off
- **Theme tag(s):** slow, indoor
- **Overlap:**

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
