---
artifact: people/<person>.md
schema-version: 1
trip: cross-trip
writer: human
lifecycle: persist-mutable
provenance: human
publish: internal-hard
---

# Noor

> **Illustrative, sanitized example. Not a real person.** No real personal detail
> appears in this file, and none ever may: this class is `publish: internal-hard`
> and every real instance of it is git-ignored. This one is tracked **only** because
> the schema gate needs a witness it can reach.

**The H1 is the display name and nothing else.** Not `# Travel Profile — Noor`, not a
decorated title: the normalized H1 is the key creation refusal asserts over, and any
decoration would enter that normalization and change the key. The person's **id** is the
filename, `psn-3c7e`, and it is not restated anywhere inside the file —
`reference/data-architecture.md` § 4.3 bars a second home for a value the filename
already carries.

**`trip: cross-trip` is the point of this class.** The record belongs to no trip. The
sentinel type-checks as the required `trip:` slug and no tool resolves it to a directory,
which is what lets a cross-trip artifact sit inside a model whose universal block requires
a trip.

**Eight sections, seventeen bullets, plus the H1 — eighteen durable answers.** Every label
is byte-identical to the one the trip intake form uses, because composition matches by
label and a relabelled durable field is an invisible miss. The four sections the trip form
carries that are **absent** here are absent by classification, not by omission: `About you`
empties entirely (its two remaining fields are trip-scoped and `Name` moved to the H1),
`Dates & availability` and `Desires` are trip-scoped throughout, and `Anything else` — a
free-text tail — is trip-scoped by the fail-safe default, because a durable store must not
silently carry forward text that may be about one trip.

**Nothing here is compulsory but the H1.** A skipped field is a skipped field; an em dash
is *not answered*, never an answer, and an absent durable value composes to `UNKNOWN`
rather than to *no constraints*.

---

## Destination leanings

- **Would love:** Somewhere coastal with a walkable old town.
- **Rather skip:** Long-haul flights, this year or any year.

---

## Getting there & back

- ⭐ **Leaving from:** the home airport
- **Journey comfort:** One long flight is fine; no overnight departures.
- **Passport:** —

**`Passport:` is answered with an em dash on purpose, and this is the field the class
exists to protect.** It is the one durable field known to expire, and the intake form asks
only for the issuing country and **the month it is valid through — never the number.** A
tracked, world-readable worked example is the one place even that much must not go. The
label ships because the label is the parse surface; the em dash is what keeps the field
demonstrated and empty at the same time.

**This is also where a validity horizon would ride** — the suffix mark
`[VALID-THROUGH <YYYY-MM>]`, appended to the value. It is **not exercised here**, because
exercising it would require the value this fixture must not carry. `reference/schemas/person-record.md`
is the normative home for the mark's grammar and its expiry semantics.

---

## Where you stay

- ⭐ **Lodging style:** A rental with a kitchen, ground floor or a lift.

---

## Budget appetite

- ⭐ **Comfort range:** Mid-range — simple lunches, one good dinner.
- **Splurge appetite:** —

---

## Needs — the must-haves

> Durable constraints that **bound** any plan. The trip form's third field here,
> `Applies to:`, is **absent by design**: the need-to-constraint edge is recomputed
> per trip and has no durable value to carry.
>
> **This section is the only place in the record where a relayed value may appear**, and
> that is what bounds an operator-provided record to needs alone. The two blocks below are
> the cross-provenance case the store exists to represent: one need was relayed before this
> person filed anything, and one they wrote themselves. **Both are kept; neither overwrites
> the other; and the marks say which is which.** Record-level provenance could not express
> this file at all.

- **Category:** Dietary-health
- ⭐ **Specific:** Tree-nut allergy; needs nut-free confirmation before any tasting menu. `[OPERATOR-PROVIDED]`

- **Category:** Mobility
- ⭐ **Specific:** Prefers under fifteen minutes of continuous walking before a sit-down break.

---

## Travel style & pace

- ⭐ **Pace:** Balanced — a couple of things a day with room to breathe.
- **Day rhythm:** Early riser; fading by mid-evening.
- **Novelty vs comfort:** Happy with the unfamiliar from a comfortable base.
- **Planning style:** —

---

## Interests & tastes

- ⭐ **Interests:** Markets, coastal walks, small museums.
- **Cuisine appetite:** Adventurous, minus the allergy above.

**The two destination-scoped fields the trip form carries here are absent.**
`Been here before?` and `Already done` are answers about a *destination*, not about this
person, so they stay on the trip side. `Interests` and `Cuisine appetite` are durable
statements about how this person travels and do carry between trips.

---

## People dynamics & togetherness

- **Solo, I'd:** Find a quiet café and read for an hour.

**One field of four survives from this section, and the reason is the discriminator.**
`Group time`, `Split off with` and `Whole-group moments` all name *this trip's* group, so
none of them outlives it. `Solo, I'd` has no group referent at all.
