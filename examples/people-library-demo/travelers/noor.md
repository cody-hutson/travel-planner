---
artifact: travelers/<traveler>.md
schema-version: 1
trip: people-library-demo
writer: human
lifecycle: persist-mutable
provenance: human
publish: internal
person: psn-3c7e
---

# Your Travel Profile — Noor

> **Illustrative, sanitized example. Not a real person.** No real personal detail
> appears in this file.

**This is the composition witness: a traveller file that references a durable person
record.** Its sibling [`../people/psn-3c7e.md`](../people/psn-3c7e.md) is that record.
Between them the two files carry every answerable slot of the intake form exactly once,
and which file holds which slot is decided entirely by
[`../../../reference/data-model.md`](../../../reference/data-model.md) § *Field Scope*.

**`person: psn-3c7e` is the whole of the link, and it is the only new byte a trip needs.**
One optional frontmatter field, on this class and no other. The value is the record's
surrogate id — the same id its filename carries and the id that appears nowhere inside
that file. The reference resolves under the store-root rule stated in § *Composition —
the trip-side read of a durable record*: `<trip-root>/people/` first, and this fixture
root carries one, so the resolution never leaves this directory.

**Why the store sits inside this fixture root when the real one never sits inside a trip.**
In a real working tree `people/` is a **sibling** of `trips/` — a person record is
referenced from trips and lives outside every one of them, which is the scoping the
library exists to establish. A tracked fixture cannot reproduce that layout, because the
repo-root store is git-ignored and so does not exist in a fresh checkout at all. Falling
through to it would make this witness resolve `RESOLVED` on an author's machine and
`DANGLING` in CI, and a witness whose verdict depends on someone's private working
directory is not a witness. So the fixture compresses the two roots into one directory
and relies on the store-root rule's **first** step to make that legal and deterministic.
**The compression is the fixture's, not the design's.**

**What this file deliberately does not carry, and why the absence is the point:**

| Absent | Reason |
|---|---|
| **Every `PERSON` bullet** — `Passport`, `Category`, `Specific` | The record owns them. **Zero `PERSON` bullets is the structural enforcement**: a class that cannot be overridden per trip is one whose override has nowhere to live |
| **Every `DEFAULT` bullet**, and the two sections that held only those | The record answers them and this trip does not diverge. A `DEFAULT` line here would be an override — legitimate, and reported |
| **`## Needs`** entirely | Its durable half is `PERSON` and lives in the record; its third field, `Applies to`, is never authored by anyone — enrichment computes the need-to-constraint edge per trip into `outputs/traveler-model.md` |
| **`Name`** | `DEFAULT`, and the record carries it. Here it appears once, as the title line, exactly as it does in every traveller file |

**What composes from where, for a reader checking the mechanism rather than the prose.**
Every field below is `TRIP` or `DEST`, so composition returns this file's value for all of
them and never reads the record. Every field the record holds is `PERSON` or `DEFAULT`, so
composition returns the record's value and this trip inherits it. **No field is claimed
twice, so this witness reports nothing** — it is the clean case. Its counterpart is
[`../../data-architecture-demo/travelers/`](../../data-architecture-demo/travelers/),
whose two files carry **no** reference and are the witness for the other half: a trip that
predates the store, composing to itself with no store read attempted.

---

## About you

- **Relationship:** Travelling with a friend and her brother.
- **Party:** —

**`Name` is absent and that is the split working.** It is `DEFAULT`, so the record
answers it; the title line above is the same rendering every traveller file has always
carried, not a second home for the value.

---

## Destination leanings

- ⭐ **Trip vibe:** A slow coastal week, one city day at the end.

**The other two fields in this section are `DEFAULT` and live in the record.** A standing
wishlist is durable; *the kind of trip you're after* is answered afresh every time.

---

## Dates & availability

- ⭐ **Can travel:** The first three weeks of September.
- **Blackout:** The second weekend — a wedding at home.
- **Trip length:** Six or seven nights.

**This whole section is trip-scoped and the record carries none of it.** Every answer is
dated to this trip's window.

---

## Getting there & back

- **Arrive / leave:** Arriving a day ahead of the group; leaving with everyone.

**Three fields of four are absent here, and they are absent for two different reasons.**
`Leaving from` and `Journey comfort` are `DEFAULT` — durable, and this trip does not
diverge from them. `Passport` is `PERSON`: it is not that this trip agrees with the
record, it is that **this trip may not answer it at all.** A passport value written here
would be a schema violation rather than an override, refused by composition and reported.

---

## Where you stay

- **Rooming:** Happy to share with whoever is easiest.

---

## Desires — what you want

- ⭐ **Desire:** Walk a coastal path at least once, early.
- **Priority tier:** anchor
- **Recurrence:** one-off
- **Theme tag(s):** outdoors, coastal
- **Overlap:**

- **Desire:** Find one long lunch with nothing scheduled after it.
- **Priority tier:** wish
- **Recurrence:** one-off
- **Theme tag(s):** food, rest
- **Overlap:**

**Desires are `TRIP` even though they read like preferences.** They are anchored to this
destination and this occasion, and their source of truth is this file. `Overlap` is the
section's second never-asked field — who else on **this** trip shares the want — and is
left blank here because a blank is what an unanswered computed field looks like.

---

## Interests & tastes

- **Been here before?:** —
- **Already done:** —

**These two are `DEST`, not `PERSON` and not `DEFAULT`.** They answer a question about a
*destination*, so they stay on the trip side and the record holds neither. The two
durable fields this section carries in the full form — how this person's interests and
appetite run generally — are in the record.

---

## People dynamics & togetherness

- **Group time:** Most dinners together; days can be loose.
- **Split off with:** —
- **Whole-group moments:** The last night.

**One field of four is missing and it is the one with no group referent.** `Solo, I'd`
survives a change of group, so it is `DEFAULT` and the record answers it; the other three
all name *this* trip's group and cannot outlive it.

---

## Anything else

- **Special occasion?:** —

Nothing further.

**The unlabelled tail is trip-scoped by the fail-safe default**, so it stays here even
though it looks durable. A durable store must not silently carry forward free text that
may be about one trip, and it is the highest-risk copy for privacy. That is an explicit
classification, not an omission.
