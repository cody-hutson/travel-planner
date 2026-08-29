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

Both travellers filed a usable profile, so neither fallback branch is exercised
here: there is no `[OPERATOR-PROVIDED]` entry and no `[THIRD-PARTY]` entry. That is
a **property of this fixture, not of the model** — the fallback branches are
specified in `reference/data-model.md`, and a `[THIRD-PARTY]` value would in any
case be barred from every publish-bound artifact, which is why a tracked worked
example is the wrong place to demonstrate one.
