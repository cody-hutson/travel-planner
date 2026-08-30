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

# Satisfaction Metrics [DERIVED]

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
| Alex | Afternoon sun not tolerable outdoors | heat | `HC-2` | May 14 (Thu), May 16 (Sat) — the only days carrying an **afternoon** outdoor block, which is what `HC-2` reaches | pass · pass |
| Alex | No shellfish | dietary-health | `DH-1` | May 14–17 (all 4) — every day carries a group meal for the constraint to bind on | pass · pass · pass · pass |
| Robin | Level or lift approaches only | mobility | `HC-1` | May 14–17 (all 4) | pass · pass · pass · pass |
| Robin | One slow afternoon mid-trip | rest | — | May 15 (Fri), May 16 (Sat) — the two full days; a partial arrival or departure day has no afternoon to grade | pass · pass |
| Sam `[OPERATOR-PROVIDED]` | Cannot manage long walks between blocks | mobility | `HC-1` | May 14–17 (all 4) | pass · pass · pass · pass |

**0 fails over 16 graded (need, day) pairs.**

**Sam's row is graded exactly like the other three.** An operator-provided need is a
need: the fallback changes where the value came from and how it is marked, never
whether it binds. A fixture that graded only the travellers who filed profiles would
model the opposite rule — that an absent profile means no constraints — which is the
one reading the model forbids.

The heat row is the one that shows the applicable-day set is **computed, not
assumed**. Grading it on all four days would report two passes the plan never earned:
Friday carries no outdoor block at all, and Sunday's is a 09:30 river walk — a morning
block, hours clear of the window, which `HC-2` never reaches.

**Both graded days pass *because the constraint moved the block*, not because it was
never at risk, and the difference is the whole point of grading them.** `HC-2` reads
*any block that would sit in direct sun in that window is moved, shaded, or given an
indoor bailout* — so its applicable days are the ones carrying a block it had to act
on. Thursday's garden block is placed at 17:00 and Saturday's viewpoint was **re-timed
from 14:00 to 16:30** by the patch this version records
(`outputs/final-itinerary-v1.md`). Neither now sits inside 13:00–16:00; both are the
constraint's own work, and a reading that dropped these two days would report the
constraint as having done nothing.

**The `DH-1` row is the one that shows a pass has to have something to pass on.** A
dietary constraint is graded per day against the group meals that day carries, so on a
plan that placed no meal anywhere the row would read four passes over four days holding
nothing for it to bind to — a verdict with no subject. Every day now carries an anchor
meal (`outputs/final-itinerary.md` § *Food Anchors*, four of four), so each of these
four passes is a real reading. That is what makes the row and the
`agents/06-validator.md` structural-integrity check agree instead of talking past each
other.

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
| Alex | Watch a sunset from a rooftop | anchor | **covered** | `evt-5ab8` |
| Alex | Spend real time in a good bookshop | wish | **covered** | `evt-3f9a` |
| Alex | See a working food market | nice-to-have | **covered** | `evt-1d60` |
| Robin | See contemporary art | anchor | **covered** | `evt-b47e` |
| Robin | Walk along the river | wish | **covered** | `evt-2f77` |
| Robin | Watch a sunset from a rooftop | wish | **covered** | `evt-5ab8` |
| Robin | Hear live fado | nice-to-have | **not covered** | — |

**6 covered / 1 not covered, of 7.** Every anchor and every wish is covered; the one
uncovered desire is a nice-to-have. `evt-5ab8` covers two rows at once, which is the
placement the desire-overlap signal in `outputs/traveler-model.md` exists to find.

**Sam contributes no row, and that is not the same as contributing a `not covered`
one.** The operator supplied needs only, so Sam's desire set is `unknown` rather than
empty — and a `not covered` row would assert a want that nobody stated. The absence is
declared in `outputs/traveler-model.md` § *Sam*, so it reads as unknown rather than as
a gap in this table.

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
| Meal-variety concentration (per day) | balance signal — scoring undefined | tracked per day — one anchor meal on each of the four days, four distinct venues |

**"Tracked" is the honest entry, and an unscored signal is not a missing one.** The
four experience axes are listed individually rather than as one row because they are
four named signals in the model, and collapsing them here would under-report the
dimension set this file is the home of.
