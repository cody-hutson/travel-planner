---
artifact: people/<person>.md
schema-version: 1
trip: cross-trip
writer: human
lifecycle: persist-mutable
provenance: human
publish: internal-hard
---

# Rhian

> **Illustrative, sanitized example. Not a real person.** No real personal detail
> appears in this file, and none ever may: this class is `publish: internal-hard`
> and every real instance of it is git-ignored. This one is tracked **only** because
> the validity horizon needs an instance the schema gate can reach.

**This record exists to exercise the validity horizon, which its sibling deliberately
does not.** `psn-3c7e.md` states in its own prose that the mark is *not exercised here*,
because exercising it on `Passport` would require the value that file must not carry.
That reasoning is correct and unchanged — and it is also why the horizon needed a second
record rather than an edit to the first. **`psn-3c7e.md` remains the schema's declared
witness**; this file is an ordinary instance of the same class beside it.

**The horizon is demonstrated on fields that are not `Passport`, and that is the point.**
`reference/data-model.md` § *Field Scope → The classification* carries a per-field
`Horizon` axis, so the mechanism is a property of *fields* rather than of one field.
A passport-specific mechanism would have had no safe witness at all: the class forbids a
passport value in a tracked file, so the only demonstrable instance would have been one
that must never be written. **A field-general mechanism can be exercised in a tracked file
without any passport value ever entering one**, which is what makes this fixture possible.

**Both field scopes are exercised, because a lapsed horizon behaves differently on each.**
A **slot**-scoped field has one owner for one fact, so a lapsed value composes `UNKNOWN`
and is reported. A **block**-scoped field is one instance among several, so a lapsed block
is **retained in the union and reported** — never dropped, because a vanished constraint
reads as compliance. `## Where you stay` below carries the slot case and `## Needs` the
block case.

**The months below are fixture data, not live assertions.** Nothing asserts what verdict
either mark currently yields; what is asserted is that the mark is present and parseable
on a bullet of each scope. A fixture whose green depended on today's date would rot on a
calendar rather than on a change to the corpus.

---

## Destination leanings

- **Would love:** Somewhere flat, with a train station in walking distance.
- **Rather skip:** —

---

## Getting there & back

- ⭐ **Leaving from:** the home airport
- **Journey comfort:** Aisle seat; a stop is fine if the legs are shorter.
- **Passport:** —

**`Passport:` is em-dashed here for exactly the reason it is em-dashed in the sibling.**
The field is the class's most sensitive, the intake form asks only for an issuing country
and a validity *month*, and a tracked, world-readable worked example is the one place even
that much must not go. **`Passport` is the sole field whose `Horizon` axis reads
`required`** — so it is the one field for which an absent mark is a defect rather than a
non-event, and this file is therefore a standing instance of that condition. That is
correct and stated rather than hidden: the em dash means the field is unanswered, and an
unanswered field has no value for a horizon to qualify.

---

## Where you stay

- ⭐ **Lodging style:** Ground floor or a lift, while a knee heals. `[VALID-THROUGH 2024-11]`

**This is the slot-scoped horizon, and it is deliberately in the past.** A ground-floor
requirement held while an injury heals is a durable answer with a genuine end date — the
shape the mark exists for, on a field that is not `Passport`. Because the month is behind
any plausible reference month, the composed verdict is stable: the value is `EXPIRED`, the
composition returns `UNKNOWN` rather than the stale answer, and the report carries the
disposition with the remedy *refresh the record*. **Nothing here is silently used and
nothing is silently dropped** — the two failures the mark exists to prevent.

---

## Budget appetite

- ⭐ **Comfort range:** Mid-range, with room for one good meal a week.
- **Splurge appetite:** —

---

## Needs — the must-haves

> Durable constraints that **bound** any plan. The trip form's third field here,
> `Applies to:`, is **absent by design**: the need-to-constraint edge is recomputed
> per trip and has no durable value to carry.

- **Category:** Mobility
- ⭐ **Specific:** No stairs to the room while a knee heals. `[VALID-THROUGH 2024-11]`

- **Category:** Dietary-health
- ⭐ **Specific:** Coeliac — strictly gluten-free, with no end date.

**This is the block-scoped horizon, and the pair is what makes it legible.** The first
block carries a mark and the second does not, in the same section of the same record, so
the mark is visibly a property of a block rather than of the section or of the file. Under
the block rule the lapsed block is **retained in the composed union and reported** — it is
not removed from the union, because removing a need is a destructive act and linking a
person is never one. The un-marked block is unaffected: a `Horizon` axis of `admissible`
means a mark is honoured where present and its absence is not a finding.

---

## Travel style & pace

- ⭐ **Pace:** Slow — one anchor a day is plenty.
- **Day rhythm:** —
- **Novelty vs comfort:** —
- **Planning style:** Likes the day sketched, not scheduled.

---

## Interests & tastes

- ⭐ **Interests:** Botanic gardens, secondhand bookshops, long lunches.
- **Cuisine appetite:** —

---

## People dynamics & togetherness

- **Solo, I'd:** Sit somewhere with a view and write postcards.
