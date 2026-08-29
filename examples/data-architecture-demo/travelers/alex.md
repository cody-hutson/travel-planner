---
artifact: travelers/<traveler>.md
schema-version: 1
trip: data-architecture-demo
writer: human
lifecycle: persist-mutable
provenance: human
publish: internal
---

# Traveler — Alex

> **Illustrative, sanitized example. Not a real person.** No real personal detail
> appears in this file.

**The traveller's name is the title line, never a frontmatter value.** `artifact:`
carries the **class string** `travelers/<traveler>.md` exactly as
`reference/data-architecture.md` § 1.1 spells it — the same string
`templates/traveler-intake.template.md` ships. A file whose `artifact:` read
`travelers/alex.md` would be finding `A5`: the value names an instance path, and
the field's domain is one value per class row.

## Getting there & back

- **Leaving from:** the group's origin
- **Arrive / leave:** same as the group

Single origin, one booking — both fields elect the group, so both bases resolve
`ASSERTED-SAME`.

## Needs

Constraints that **bound** the solution. Each links to the governing trip-level
constraint and restates none of its text — `trip-context.md` § *Hard Constraints*
and § *Dietary & Health* are the source of truth.

| Need | Category | Applies to |
|------|----------|-----------|
| Afternoon sun is not tolerable for long outdoor stretches | heat | `HC-2` |
| No shellfish | dietary-health | `DH-1` |

## Desires

Wants optimized **within** those bounds. Tier is a priority label, not a weight,
and recurrence is orthogonal to it.

| Desire | Tier | Recurrence | Themes |
|--------|------|-----------|--------|
| Watch a sunset from a rooftop | anchor | one-off | views, evening |
| Spend real time in a good bookshop | wish | one-off | browsing, indoor |
| See a working food market | nice-to-have | one-off | local, food |

**Desire overlap.** *Watch a sunset from a rooftop* is also held by Robin, at a
lower tier. The enrichment agent carries that overlap into
`outputs/traveler-model.md`; nothing here computes it.
