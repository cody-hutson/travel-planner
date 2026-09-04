---
artifact: outputs/traveler-model.md
schema-version: 1
trip: archived-trip-demo
writer: enrichment
lifecycle: rebuilt-each-synthesis
provenance: derived
publish: internal-hard
generated: 2025-10-08
---

# Traveler Model [DERIVED]

> **Illustrative, sanitized example. Not real people.**

**`generated:` predates the erasure, and that is a signature rather than staleness.**
The date above is the last time this model was *composed*, while the trip was still
active. The erasure that later reached this file substituted values into it and did not
rebuild it, so the composition date did not move. A regeneration would have moved it.

**Every `##` heading in this file is read as a person unless its key is reserved.**
`scripts/publish-trip-site.sh` lowercases each `## ` heading, strips every non-`[a-z0-9]`
character and treats the result as a traveler key — unless that key is on the reserved
list `reference/data-model.md` § *Reserved keys* holds, whose two members at this schema
version are `updatesignals` and `desireoverlap`. This file adds no structural `##`
heading beyond those two.

**Four entries, three of them tombstoned, and the census is the point.** This is the
only fixture in the repository carrying all three model-entry classes at once, and the
only one carrying an entry with **both** `[OPERATOR-PROVIDED]` and `[THIRD-PARTY]`.
`examples/data-architecture-demo/` states in terms that it leaves that branch
unexercised, so before this fixture the class whose archived-erasure behaviour is
hardest to get right had nothing asserting it.

| Entry | Durable surface outside this file | Class | Erased here |
|---|---|---|---|
| Dana | `travelers/dana.md` + the `## Group` roster row | first-party | no — the control |
| per-4f1c | `travelers/per-4f1c.md` + the `## Group` roster row | first-party | yes |
| per-9a3e | the `## Group` roster row **only** — no profile | `[OPERATOR-PROVIDED]` alone | yes |
| per-b70d | **none** — no roster row, no file anywhere | both marks | yes |

**Why the census is what tells substitution from regeneration.** A regeneration
recomposes this file from the per-traveler sources. Two of these four entries have no
such source: the `[OPERATOR-PROVIDED]`-alone entry would be **dropped** by a rebuild,
and the both-marks entry would be **carried forward verbatim** — name and need intact —
because `agents/00-enrichment.md` preserves exactly that class rather than re-deriving
it. Those two failures run in opposite directions, which is why neither one alone
detects a wrong mechanism. A file that still holds all four entries, with the two
file-less ones tombstoned rather than dropped or preserved, could not have been produced
by a rebuild.

## Dana

**Source:** `travelers/dana.md`

**Needs**

| Need | Category | Governing constraint |
|------|----------|---------------------|
| No shellfish | dietary-health | `DH-1` |

**Desires**

| Desire | Tier | Recurrence |
|--------|------|-----------|
| Walk the canals early | anchor | one-off |

**Derived**

- **Documents:** —

## per-4f1c `[ERASED]`

**Source:** `travelers/per-4f1c.md`

**Needs**

| Need | Category | Governing constraint |
|------|----------|---------------------|
| Stairs are hard; level or lift approaches only | mobility | `HC-1` |

**Desires**

| Desire | Tier | Recurrence |
|--------|------|-----------|
| See one thing properly rather than three quickly | anchor | one-off |

**Derived**

- **Documents:** —

## per-9a3e `[ERASED]` `[OPERATOR-PROVIDED]`

**Source:** none — no profile was filed. Needs supplied by the operator and marked as
such; this entry is the **fallback branch**, not a projection.

**Needs**

| Need | Category | Governing constraint |
|------|----------|---------------------|
| Needs a seated rest stop in any long block | rest | `HC-2` |

**Desires**

*None recorded.* The operator supplied needs only. **An absent desire set is `unknown`,
never "no desires"**, so this entry contributes no row to a desire-coverage table.

**Derived**

- **Documents:** unknown — no passport country on file

## per-b70d `[ERASED]` `[OPERATOR-PROVIDED]` `[THIRD-PARTY]`

**Source:** none, and none is possible — this is the party member who will never file a
profile, whose needs the operator supplied *about* them. Needs only, no file created
anywhere, and no entry at all without operator input.

**Needs**

| Need | Category | Governing constraint |
|------|----------|---------------------|
| Tires quickly; long standing is not manageable | rest | — (traveller-scoped; no trip-level constraint) |

**Desires**

*None recorded.* `ADR-006` restricts this class to needs.

**Derived**

- **Documents:** unknown — no passport country on file

**This entry names no trip-level constraint, and the em dash is structural rather than
an omission.** `reference/adr/ADR-006-third-party-data-capture.md` bars a `[THIRD-PARTY]`
value from escalating into `trip-context.md`: it triggers no new constraint, and its
subject is never added to an existing constraint's `Applies to:` roster. So this person
has **no** surface outside this file — no roster row, no traveller file, no constraint
mention. That is what makes their post-reopen disposition a theorem rather than a hope:
a first pass after reopen cannot re-enumerate them, because there is nowhere to
re-enumerate them from, and nothing points at them to dangle.

**Conditional on that restriction holding.** If a later release lets a third-party need
reach `trip-context.md`, the theorem lapses and this entry's post-reopen disposition
must be re-derived rather than assumed.

## Update signals [DERIVED]

> Candidate replanning triggers. The hub owns whether and how to re-plan.

*No signals.* **The emptiness is declared, not inferred from silence.** This trip is
`ARCHIVED`, and an archived trip receives no derivation — no update signal, no
regeneration, no refresh (`CLAUDE.md` § *Archived trips — what the freeze binds*). A
person record referenced by this trip may have been edited since; if it was, the edit is
named in the discovery report as `ARCHIVED — not signalled` and **no signal is written
here**. A signal line appearing in this block would mean the freeze had failed.

## Desire overlap

| Desire | Held by | Tiers | Overlap |
|--------|---------|-------|---------|
| Walk the canals early | Dana | anchor | no |
| See one thing properly rather than three quickly | per-4f1c | anchor | no |

**Two of the four entries hold no desires**, so they appear in no row here. That is the
`unknown`-not-empty rule above, and not a gap in this table.
