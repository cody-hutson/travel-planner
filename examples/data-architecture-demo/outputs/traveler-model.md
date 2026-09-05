---
artifact: outputs/traveler-model.md
schema-version: 1
trip: data-architecture-demo
writer: enrichment
lifecycle: rebuilt-each-synthesis
provenance: derived
publish: internal-hard
generated: 2026-08-29
---

# Traveler Model [DERIVED]

> **Illustrative, sanitized example. Not real people.**

Reconciled from the composed per-traveler source — each `travelers/<traveler>.md`
together with the durable person record it references, which for a file carrying no
reference is that file alone (`reference/data-model.md` § *Composition*). Every entry
here is a **projection** — the composed source is authoritative — so this file is safe
to rebuild on every synthesis. `publish: internal-hard`: the site build excludes it and
the hub applies it as a hard bound before any objective.

**Every `##` heading in this file is read as a person unless its key is reserved.**
`scripts/publish-trip-site.sh` parses this class by taking each `## ` heading,
lowercasing it and stripping every non-`[a-z0-9]` character, and treating the result as
a **traveler key** — *unless* that key is on the declared reserved list, which
`reference/data-model.md` § *Reserved keys* holds and which carries exactly two members
at this schema version: `updatesignals` (`## Update signals [DERIVED]`) and
`desireoverlap` (`## Desire overlap`). A structural section whose key is **not** on that
list is counted as a **person** — a phantom entry, which is what keeps the
`entries == 0` fail-closed sentinel from firing on a model that has drifted.

**So this file carries no structural `##` heading beyond the reserved one.** The roster
correspondence that would naturally want a section of its own is written into this
preamble instead, above the first entry, where the parse is not inside any entry at all.
The alternative — a new `##` heading — would require adding its key to the reserved list
in the same edit, which `reference/data-model.md` states in terms is how that list
grows. **This fixture cannot take that edit** (the list is model-and-guard scope), so it
takes the shape that needs no edit. A reader replicating this file into a real trip
inherits the safe shape rather than a heading the guard counts as a person.

**Roster correspondence — three members, two source files, three entries.** The
correspondence is not one-to-one and is not meant to be: every `travelers/<name>.md`
stem resolves to an entry here, but an entry can exist without a file. That is the
fallback, and reading the two counts as a mismatch is the misreading this note exists to
prevent.

| Roster member | Source file | Entry | Branch |
|---|---|---|---|
| Alex | `travelers/alex.md` | projected | normal |
| Robin | `travelers/robin.md` | projected | normal |
| Sam | — | operator-supplied | `[OPERATOR-PROVIDED]` |

**Lifecycle facets are carried for a first-party entry and are unstated here.** Beyond
needs and desires, `agents/00-enrichment.md` carries nine facet groups per traveller —
party, destination leanings, dates, journey & origin, accommodation, budget appetite,
travel style, interests, people dynamics. Both source profiles answer the journey group
and em-dash the rest, and an em dash is *not answered* rather than an answer, so this
projection carries no facet value for anyone. The labels exist in the source and the
absence is declared here rather than inferred from an empty section — the degenerate
case is part of the shape.

**`Documents:` is derived content, not a facet — so its presence below does not
contradict the paragraph above.** The per-traveller document set is computed from a
traveller's facets plus researched entry policy rather than stated by the traveller
(`agents/00-enrichment.md` § *Derive the per-traveler document set*;
`reference/data-model.md` § *Lifecycle facets*), so no reader should take it for an
added facet. Its **value** is em-dashed on the two projected entries for the same
reason `Passport:` is em-dashed in the source profiles: `reference/data-architecture.md`
§ 5.6 now carries a `Documents` row scoped to this very class, and a tracked,
world-readable worked example is the one place a declared non-publishable value must not
go. The label ships because the guard's field limb reads it from this class; the em dash
keeps the field demonstrated and empty at the same time. Sam's entry states `unknown`
instead, and that is not an exception to the rule: `unknown` is the declared *absence*
the profile-less branch requires, never a derived set.

## Alex

**Source:** `travelers/alex.md`

**Needs**

| Need | Category | Governing constraint |
|------|----------|---------------------|
| Afternoon sun not tolerable for long outdoor stretches | heat | `HC-2` |
| No shellfish | dietary-health | `DH-1` |

**Desires**

| Desire | Tier | Recurrence |
|--------|------|-----------|
| Watch a sunset from a rooftop | anchor | one-off |
| Spend real time in a good bookshop | wish | one-off |
| See a working food market | nice-to-have | one-off |

**Recurrence is rendered only when it is `daily`** in a live projection; every desire in
this fixture is `one-off`, so the column is shown here for the fixture's own
readability and carries the same value throughout. The tier is a structural priority
label, never a weight, and nothing here scores it.

**Derived**

- **Documents:** —

## Robin

**Source:** `travelers/robin.md`

**Needs**

| Need | Category | Governing constraint |
|------|----------|---------------------|
| Stairs are hard; level or lift approaches only | mobility | `HC-1` |
| One genuinely slow afternoon mid-trip | rest | — (traveller-scoped; no trip-level constraint) |

**Desires**

| Desire | Tier | Recurrence |
|--------|------|-----------|
| See contemporary art | anchor | one-off |
| Walk along the river | wish | one-off |
| Watch a sunset from a rooftop | wish | one-off |
| Hear live fado | nice-to-have | one-off |

**Derived**

- **Documents:** —

## Sam `[OPERATOR-PROVIDED]`

**Source:** none — no profile was filed. Needs supplied by the operator and marked as
such; this entry is the **fallback branch**, not a projection.

**Needs**

| Need | Category | Governing constraint |
|------|----------|---------------------|
| Cannot manage long walks between blocks | mobility | `HC-1` |

**Desires**

*None recorded.* The operator supplied needs only, which is what the fallback admits.
**An absent desire set is `unknown`, never "no desires"** — the same rule that makes an
absent profile *unknown* rather than *no constraints*. So Sam contributes **no** rows
to `outputs/satisfaction-metrics.md` § *Desire-coverage*, and the absence is recorded
here rather than inferred from an empty table there.

**Derived**

- **Documents:** unknown — no passport country on file

  The profile-less form. A traveller with no filed profile still carries the line, so a
  consumer reads *unknown* rather than *nothing required* — the same rule that makes an
  absent profile *unknown* rather than *no constraints*. It is the declared absence, not
  a derived set, which is why it is stated here where a real value would not be.

This entry is **`[OPERATOR-PROVIDED]` and not `[THIRD-PARTY]`.** Sam is a party member
who has simply not filed a profile yet, so the entry is a placeholder for a source
that may still arrive. `[THIRD-PARTY]` marks a person who will never file one and
whose needs were supplied second-hand about them; that mark additionally bars the
value from every publish-bound artifact. The two are different fallbacks with
different downstream rules, and this fixture exercises the first.

**The sentence above is itself read by the guard's entry limb, and in the safe
direction.** `[THIRD-PARTY]` is a declared entry selector, matched as a literal
substring of an entry heading **and** of each raw value line inside it — so naming the
mark in prose inside a person's entry admits that line's value to the non-publishable
class even though the entry is not third-party. That is over-classification, which is
the direction a fail-closed guard is built to err in; the opposite reading, a mark that
resolved to nothing, is the orphaned-mark condition and aborts the publish as
UNDETERMINED.

## Desire overlap

The signal the hub reads when one placement can serve more than one traveller. **This
is also the host of the attention signal** — the attention engine's objective is
produced here, on the enrichment agent's own file, and never on a spoke's.

| Desire | Held by | Tiers | Overlap |
|--------|---------|-------|---------|
| Watch a sunset from a rooftop | Alex, Robin | anchor / wish | **yes — 2 travellers** |
| See contemporary art | Robin | anchor | no |
| Spend real time in a good bookshop | Alex | wish | no |
| Walk along the river | Robin | wish | no |
| See a working food market | Alex | nice-to-have | no |
| Hear live fado | Robin | nice-to-have | no |

`desireoverlap` is the normalized key of this heading and it **is** on the declared
reserved list, which is why this section is a structural section rather than a seventh
person. It is the one `##` heading in this file that is not an entry.

**No `[THIRD-PARTY]` entry appears here, deliberately.** That branch covers a person
who will never file a profile and whose needs the operator supplies *about* them; its
values must not reach any publish-bound artifact in attributed or anonymized form.
`outputs/traveler-model.md` is `publish: internal-hard` and would be a legal home for
one — but a **tracked, world-readable worked example** is not the place to model
second-hand data about a person, even a fictional one, so the branch is named here
and left unexercised.
