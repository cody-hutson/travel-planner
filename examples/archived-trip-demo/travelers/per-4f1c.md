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

## Trip-local overrides

- **Loyalty number:** —
- **Emergency contact:** —

**These two fields are the override witness, and no schema declares either of them.** A
trip-local override is a divergent copy of a durable field sitting in this file — the
operator typed it here because this trip diverged from the record. Neither label appears in
`templates/traveler-intake.template.md`, and `reference/schemas/traveler-profile.md`
constrains frontmatter only, so **no field enumeration anywhere reaches them.** That is the
whole of why the erasure verb declares this file *rewritten rather than field-edited*: a
field-by-field pass can only reach the fields someone listed, and the first unlisted
override survives the erasure still carrying an identifying value.

**Both now read the form's not-answered sentinel while the need above survives verbatim**,
and that pairing is what makes the sentinel a measurement. A wholesale rewrite blanks the
personal values and keeps the needs and their `Applies to:` link; a file blanked outright
would take the need with it, and an enumerating pass would leave these two standing.
`travelers/dana.md` carries the same two fields with real values — the control arm, without
which "every override is a sentinel" is satisfied just as well by a probe that found no
override at all. `scripts/test-artifact-schema.sh` arm `ER15` is the assertion, and it is
the first witness the override-sweep half of this milestone's test criterion has had.

---

## Anything else

- **Special occasion?:** —

—
