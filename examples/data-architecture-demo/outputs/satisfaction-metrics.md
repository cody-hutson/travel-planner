---
artifact: outputs/satisfaction-metrics.md
schema-version: 1
trip: data-architecture-demo
writer: [hub, validator]
lifecycle: rebuilt-each-synthesis
provenance: derived
publish: internal-hard
generated: 2026-08-29
---

# Satisfaction Metrics

> **Illustrative, sanitized example. Not a real trip.**

**`writer: [hub, validator]` is the one declared non-scalar in the whole grammar.**
It is admitted by **type** on this one field — `list<slug>` — never by widening the
frontmatter grammar for every class. The two writers are **section-owned** and
read-merge-write only their own sections, so they never clobber each other.

This layer **defines dimensions and does not score them.** Two dimensions carry a
fixed type and are emitted; the rest are named balance signals whose formulas,
weights and thresholds are left to design, because nothing here optimizes yet.

---

## Needs-compliance — *validator-owned*

**Type: pass / fail, per need, per applicable day.** The structured recorded form of
the every-applicable-day hard-constraint audit — not a balance score.

Applicable days are the days the governing constraint governs, **intersected with
that traveller's at-destination day set**. Both travellers are present all four
days here, so the intersection never narrows the set; what does narrow it is the
constraint's own reach, which is why two of the four rows cover fewer than four days.

| Traveller | Need | Category | Governing | Applicable days | Verdict |
|---|---|---|---|---|---|
| Alex | Afternoon sun not tolerable outdoors | heat | `HC-2` | May 14 (Thu), May 16 (Sat) — the only days carrying an outdoor block in the 13:00–16:00 window | pass · pass |
| Alex | No shellfish | dietary-health | `DH-1` | May 14–17 (all 4) | pass · pass · pass · pass |
| Robin | Level or lift approaches only | mobility | `HC-1` | May 14–17 (all 4) | pass · pass · pass · pass |
| Robin | One slow afternoon mid-trip | rest | — | May 15 (Fri), May 16 (Sat) — the two full days; a partial arrival or departure day has no afternoon to grade | pass · pass |

**0 fails over 12 graded (need, day) pairs.**

The heat row is the one that shows the applicable-day set is **computed, not
assumed**. Grading it on all four days would report two passes the plan never
earned, because Friday and Sunday carry no outdoor block in that window at all.

## Agreement check — *validator-owned*

Agreement with constraint-compliance is **forward-only**: every needs-compliance
`fail` is a constraint Critical; a trip-level constraint with no linked per-traveler
need yields a constraint Critical with **no** needs-compliance row, by design.

- 0 needs-compliance fails; `outputs/validation-report.md` carries
  `critical-count: 0`. The forward implication holds, vacuously.
- `HC-1`, `HC-2` and `DH-1` each carry a linked per-traveler need, so the
  one-directional gap the rule names is **not exercised** by this fixture. Stated
  rather than left to be inferred from its absence.
- Robin's rest need runs the other way — a need with **no** governing trip-level
  constraint. It is a legitimate row and it is the reason the rule is written
  one-directionally rather than as an equivalence.

---

## Desire-coverage — *hub-owned*

**Type: covered / not covered, per traveller, per desire.** A boolean, not a degree.

| Traveller | Desire | Tier | Covered | By |
|---|---|---|---|---|
| Alex | Watch a sunset from a rooftop | anchor | **covered** | `EV-5ab8` |
| Alex | Spend real time in a good bookshop | wish | **covered** | `EV-3f9a` |
| Alex | See a working food market | nice-to-have | **covered** | `EV-1d60` |
| Robin | See contemporary art | anchor | **covered** | `EV-b47e` |
| Robin | Walk along the river | wish | **covered** | `EV-2f77` |
| Robin | Watch a sunset from a rooftop | wish | **covered** | `EV-5ab8` |
| Robin | Hear live fado | nice-to-have | **not covered** | — |

**6 covered / 1 not covered, of 7.** Every anchor and every wish is covered; the one
uncovered desire is a nice-to-have. `EV-5ab8` covers two rows at once, which is the
placement the desire-overlap signal in `outputs/traveler-model.md` exists to find.

The `not covered` row is deliberate. A coverage table whose every cell reads the
same way demonstrates one of the boolean's two values and asserts the other.

## Balance signals — *hub-owned*

Named and tracked; **scoring left to design.** Recording a number here would invent
a weighting the model does not define.

| Signal | Type | This trip |
|---|---|---|
| Group-equity | balance signal — scoring undefined | tracked; both travellers hold a covered anchor |
| Experience axis — creativity | balance signal — scoring undefined | tracked |
| Experience axis — fun | balance signal — scoring undefined | tracked |
| Experience axis — excitement | balance signal — scoring undefined | tracked |
| Experience axis — newness | balance signal — scoring undefined | tracked |
| Rest-recovery balance | balance signal — scoring undefined | tracked; one slowed afternoon on May 16 (Sat) |
| Meal-variety concentration (per day) | balance signal — scoring undefined | tracked per day |

**"Tracked" is the honest entry, and an unscored signal is not a missing one.** The
four experience axes are listed individually rather than as one row because they are
four named signals in the model, and collapsing them here would under-report the
dimension set this file is the home of.
