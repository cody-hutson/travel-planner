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

Reconciled from the per-traveler source files. Every entry here is a **projection**
— `travelers/<traveler>.md` is authoritative — so this file is safe to rebuild on
every synthesis. `publish: internal-hard`: the site build excludes it and the hub
applies it as a hard bound before any objective.

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

This entry is **`[OPERATOR-PROVIDED]` and not `[THIRD-PARTY]`.** Sam is a party member
who has simply not filed a profile yet, so the entry is a placeholder for a source
that may still arrive. `[THIRD-PARTY]` marks a person who will never file one and
whose needs were supplied second-hand about them; that mark additionally bars the
value from every publish-bound artifact. The two are different fallbacks with
different downstream rules, and this fixture exercises the first.

## Desire overlap

The signal the hub reads when one placement can serve more than one traveller.

| Desire | Held by | Tiers | Overlap |
|--------|---------|-------|---------|
| Watch a sunset from a rooftop | Alex, Robin | anchor / wish | **yes — 2 travellers** |
| See contemporary art | Robin | anchor | no |
| Spend real time in a good bookshop | Alex | wish | no |
| Walk along the river | Robin | wish | no |
| See a working food market | Alex | nice-to-have | no |
| Hear live fado | Robin | nice-to-have | no |

## Coverage of the roster

Three roster members, **two** source files, three entries. The correspondence is not
one-to-one and is not meant to be: every `travelers/<name>.md` stem resolves to an
entry here, but an entry can exist without a file. That is the fallback, and reading
the two counts as a mismatch is the misreading this section exists to prevent.

| Roster member | Source file | Entry | Branch |
|---|---|---|---|
| Alex | `travelers/alex.md` | projected | normal |
| Robin | `travelers/robin.md` | projected | normal |
| Sam | — | operator-supplied | `[OPERATOR-PROVIDED]` |

**No `[THIRD-PARTY]` entry appears here, deliberately.** That branch covers a person
who will never file a profile and whose needs the operator supplies *about* them; its
values must not reach any publish-bound artifact in attributed or anonymized form.
`outputs/traveler-model.md` is `publish: internal-hard` and would be a legal home for
one — but a **tracked, world-readable worked example** is not the place to model
second-hand data about a person, even a fictional one, so the branch is named here
and left unexercised.
