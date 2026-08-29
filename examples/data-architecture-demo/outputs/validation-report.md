---
artifact: outputs/validation-report.md
schema-version: 1
trip: data-architecture-demo
writer: validator
lifecycle: rebuilt-each-synthesis
provenance: derived
publish: internal
generated: 2026-08-29
critical-count: 0
---

# Validation Report

> **Illustrative, sanitized example. Not a real trip.**

**`critical-count` is this class's one per-class field** — the single declared
extension to the universal block. It is an `integer`, and its value must equal the
number of Critical findings the body lists. Here both are **0**, which is the state
a shippable itinerary is in: a hard-constraint violation reaching the final output
is a system failure, not a finding to log and move past.

**`rebuilt-each-synthesis`:** a finding written against a superseded itinerary is
noise, so this file is recomputed rather than accumulated. That is the same reason
`outputs/satisfaction-metrics.md` is rebuilt.

## Criticals

**None.** `critical-count: 0` above agrees with this section by construction —
the number is not an independent judgement, it is a count of what follows.

## Advisories

Non-blocking. An advisory never increments `critical-count`.

| # | Finding | Where |
|---|---------|-------|
| A1 | Robin's `Hear live fado` (nice-to-have) is uncovered. No anchor or wish is uncovered, so this does not warrant a re-plan. | `outputs/satisfaction-metrics.md` § *Desire-coverage* |
| A2 | `EV-b47e` (Serralves) is `planned` and requires a booking, so one needs-booking event remains open. | `outputs/event-status.md` |
| A3 | `EV-9e34` (Casa do Livro) is an `option` carrying `requires booking? = yes`. Its flag takes effect only on promotion to `planned`; it is recorded so a reader does not mistake the pairing for an error. | `outputs/event-status.md` |

## Checks run

| Check | Result |
|---|---|
| Hard constraints audited on every applicable day | pass — 12 of 12 (need, day) pairs |
| Day-of-week closure check per venue against its scheduled day | pass |
| Venue deduplication — no anchor/alternative split, max 2 appearances | pass — Café Majestic at the cap, same role both days |
| Every 3+ hour outdoor block carries a named indoor bailout | pass — no block reaches 3 hours; Café Majestic stands as the `HC-2` bailout |
| Needs-compliance / constraint-compliance agreement (forward-only) | pass — 0 fails, 0 Criticals |
| `outputs/event-status.md` read, never written | pass — the validator reads this file and does not own it |

## What this report does not cover

The prose of any artifact. This validator audits the plan; the schema gate audits
frontmatter. Neither reads narrative body content, and a green from either says
nothing about the other.
