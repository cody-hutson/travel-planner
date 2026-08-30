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

**The section set and the severity vocabulary below are `agents/06-validator.md`
§ *Output Format*, not this fixture's own.** All sixteen sections that prompt declares
are present, in its order, and the severities are its three — **Critical**,
**Warning**, **Note**. A report that renamed them would put a second vocabulary on one
scale: a reader could not tell whether an "Advisory" was a Warning or a Note, and
nothing would arbitrate it. The heading level is this file's own — the prompt renders
these one level deeper because they sit inside its `## Output Format` section.

**Where a check is declared *not exercised*, that is a property of this fixture and
never a pass.** This example ships no external URLs, no opening hours, no prices, no
real bookings and a placeholder destination — all declared in `README.md` § *Depth* —
so several checks have no input to run against. **Recording that as a pass would be
the exact failure this report exists to prevent**, and it is the failure the earlier
version of this file committed: it reported a clean bill on a plan with no meal on any
day, omitting the one check that would have caught it. A check you cannot run is
declared, not passed.

---

## Validation Summary

| Check | Status | Critical | Warning | Note |
|-------|--------|----------|---------|------|
| Venue deduplication | pass | 0 | 0 | 0 |
| Hours / closure matrix | not exercised — no opening hours in this fixture | 0 | 0 | 0 |
| Holiday closure cascades | not exercised — placeholder destination, no calendar | 0 | 0 | 0 |
| Reservation availability | not exercised — no real bookings | 0 | 0 | 0 |
| Price staleness | not exercised — no prices in this fixture | 0 | 0 | 0 |
| Travel restrictions | not exercised — placeholder origin and destination | 0 | 0 | 0 |
| Local happenings | not exercised — illustrative dates | 0 | 0 | 0 |
| Business status | not exercised — venues are illustrative | 0 | 0 | 0 |
| Constraint compliance | pass | 0 | 0 | 0 |
| Profile-privacy non-publication (fail-closed) | pass | 0 | 0 | 0 |
| Status integrity (protected events + needs-booking) | pass | 0 | 1 | 1 |
| Satisfaction metrics (needs-compliance + coverage report) | pass | 0 | 0 | 1 |
| Bailout completeness | pass | 0 | 0 | 0 |
| Location-link completeness (every event has a Maps link) | not exercised — no external URLs by design | 0 | 0 | 0 |
| Structural integrity | pass on both anchor limbs; alternative-detail limb not exercised | 0 | 0 | 0 |
| Experiential arc (stacked-peak + rest-need floors) | pass | 0 | 0 | 0 |
| Nightlife coverage (applicable nights; no Critical tier) | pass | 0 | 1 | 0 |

**Total issues requiring action:** 2 Warning, 2 Note — the Critical total is carried in
frontmatter as `critical-count` and is not restated here. The per-check `Critical`
column above stays: it is a *per-check* count, where the frontmatter carries the
*artifact-level aggregate*. Parts and aggregate are different facts with one home each.

**Each count sits on the check that produced it**, which is what makes the column a
part rather than a second aggregate: `[W1]` and `[N1]` are *Status integrity*, `[N2]`
is *Satisfaction metrics*, `[W2]` is *Nightlife coverage*. *Structural integrity*
carries none — its two anchor limbs pass and its third is declared unexercised, which
is a status and not a finding. A count parked on the wrong check reads as a defect in
a check that never raised one.

---

## Critical Issues
> Must be resolved before this itinerary is finalized.

**None.** `critical-count: 0` above agrees with this section by construction — the
number is not an independent judgement, it is a count of what follows.

---

## Warnings
> Should be resolved if possible. Trip can proceed without resolution but with known
> risk.

**[W1] — Open booking — May 15 (Fri) — Serralves**
- **Finding:** the contemporary-art admission is `planned` and requires a booking, so
  one needs-booking event remains open with no hold against it.
- **Evidence:** `outputs/event-status.md` — the only row reading `Needs booking
  (derived) = yes`; the advance booking checklist in `outputs/final-itinerary.md`
  carries the matching single row.
- **Suggested action:** hold the timed entry before Fri May 15. Until then "all events
  locked" is false for this trip.

**[W2] — Uncovered nightlife-adjacent desire — trip-level — live fado**
- **Finding:** Robin's *hear live fado* (nice-to-have) is applicable on the two evening
  nights and is served by nothing on the plan.
- **Evidence:** `outputs/nightlife-list.md` § *Live fado*, which records it as a want
  with no venue; `outputs/satisfaction-metrics.md` § *Desire-coverage*, the one `not
  covered` row.
- **Suggested action:** none required. Nightlife coverage carries no Critical tier by
  design, every anchor and every wish is covered, and
  `outputs/final-itinerary.md` § *OPEN DECISIONS* carries the accept-or-chase decision
  with a recommended default.

---

## Notes
> Informational. No action required, but worth knowing.

**[N1] — Status/flag pairing that reads like an error and is not**
- **Finding:** `EV-9e34` is an `option` carrying `requires booking? = yes`.
- **Context:** the flag takes effect only on promotion to `planned`. An `option` is a
  bookable backup, never a primary slot, so the derived needs-booking cell correctly
  reads `no`. Recorded so a reader does not mistake the pairing for a defect.

**[N2] — Coverage asymmetry from the operator-fallback branch**
- **Finding:** Sam contributes needs-compliance rows and **no** desire-coverage rows.
- **Context:** the operator supplied needs only, so Sam's desire set is `unknown`
  rather than empty. A `not covered` row would assert a want nobody stated. The absence
  is declared in `outputs/traveler-model.md`, so it reads as unknown rather than as a
  gap in the coverage table.

---

## Venue Deduplication Report

| Venue key | Venue | Appearances | Days | Role per day | Status |
|-----------|-------|-------------|------|-------------|--------|
| `ven-b5e0` | Café Majestic | 2 | Thu 14, Sat 16 | Bailout Thu / Bailout Sat | OK — at the cap, same role both days |
| `ven-1d9f` | Casa do Livro | 1 | Sat 16 | Alt Sat | OK |
| *(the other ten keys)* | — | 1 each | — | Anchor | OK |

One row per key, not per display name. **No key appears as an anchor on one day and an
alternative on another**, and no key exceeds two appearances. An `unresolved` row would
be a mention no key reached — it would count as its own venue and name the file its
marker sits in. There are three such mentions in this tree, in the second dated section
of `outputs/activities-list.md`; they resolve to `ven-3c17`, `ven-a90d` and `ven-5e6b`
in the registry, so each counts once rather than twice, and the cap holds either way
because each of those venues appears exactly once.

Proximity venue usage (hotel-neighborhood): not exercised — this fixture records no
walking distances, so no venue can be classed as hotel-proximate.

---

## Closure Matrix

**Not exercised.** A closure matrix grades each venue's opening hours against the
day-of-week it is scheduled on, and this fixture carries no opening hours for any
venue. On a real trip every placement above takes a row here, and an `Unconfirmed`
verdict is a finding rather than a blank.

---

## Location-Link Report

**Not exercised, and this is the check most worth naming.** Every event must resolve to
a map link in `outputs/links-reference.md` and render it on its card, and **any MISSING
link is a Critical**. This fixture deliberately carries **no external URLs at all** —
`outputs/links-reference.md` states the reason: a tracked worked example shipping live
links acquires a maintenance surface that rots without any check noticing.

So the check has no input here, and this report says so rather than reporting a pass on
eleven events with no links. What the fixture *can* assert, and does under *Venue
Deduplication* above, is the weaker key-resolution property: every venue key referenced
anywhere resolves to exactly one registry row. **That is a different check** and it is
not a substitute for this one.

---

## Reservation Status

| Venue | Scheduled Day | Reservation Type | Window Status | Action Required |
|-------|--------------|-----------------|--------------|----------------|
| Serralves | Fri May 15 | Required | Open | Book now — see [W1] |
| Livraria Lello | Thu May 14 | Required | — | None — held |
| Base Porto | Sat May 16 | Required | — | None — table held |
| Casa do Livro | Sat May 16 | Recommended | — | None while it stays an `option` |

The three anchor meals take no row: all three are walk-ins with nothing to reserve.

---

## Status Integrity Report

Protected-event check (ITERATION) — every `locked`/`firmed` event must be unchanged
unless the change request named it:

| Event | Status | Named in change? | Changed this pass? | Verdict |
|-------|--------|------------------|--------------------|---------|
| Livraria Lello timed entry | `locked` | No | No | OK |
| Base Porto — rooftop at sunset | `locked` | No | No | OK |
| Mercado do Bolhão — market-hall lunch | `firmed` | No | No | OK |

Needs-booking vs. status — the booking surfaces must equal the `planned`-and-`requires
booking?` set, and no other status may appear:

| Event | Status | Requires booking? | Needs booking (expected) | On booking checklist? | Verdict |
|-------|--------|-------------------|--------------------------|-----------------------|---------|
| Serralves — contemporary art | `planned` | yes | yes | yes | OK |
| Casa do Livro — bar | `option` | yes | no | no | OK — see [N1] |
| *(the other nine rows)* | `planned` / `locked` / `firmed` | no / yes | no | no | OK |

- **One status per event:** confirmed — eleven rows, eleven events, one status each.
- **Status ↔ matrix agreement:** confirmed — the one `option` appears as `Alt` in
  `outputs/venue-matrix.md` and never as `A`; the standing bailout appears as `B`.
- **"All events locked" determinable:** Yes — 1 planned-needs-booking remains.

---

## Satisfaction Metrics Report

> Reported (not scored) to `outputs/satisfaction-metrics.md`, which carries the tables.
> This section states the verdicts and does not restate them.

- **Needs-compliance:** 0 fails over 16 graded (need, day) pairs, including the
  operator-provided need. `DH-1` is graded against four days that each carry a group
  meal — before the anchor meals were placed, that row passed on four days containing
  no meal at all, which is a pass no plan had earned.
- **Desire-coverage:** 6 covered / 1 not covered, of 7. Every anchor and every wish is
  covered; the one uncovered desire is a nice-to-have — see [W2] and [N2].
- **Balance signals:** named and tracked; scoring left to design, so no verdict is
  reported and none is withheld.
- **Needs-compliance → constraint-compliance agreement (forward only):** confirmed —
  every needs-compliance `fail` is a constraint Critical, vacuously at 0 fails; the
  constraint Critical with no linked per-traveler need is not exercised by this fixture
  and is stated as such in `outputs/satisfaction-metrics.md`.

---

## Nightlife Coverage Report

> Per applicable night only — a night with no present nightlife desire and no natural
> occasion is not applicable and is never a gap. Warning and Note only; nothing here
> blocks finalization.

| Night | Date / weekday | Applicable? | What made it applicable | Block content | Verdict |
|-------|----------------|-------------|-------------------------|---------------|---------|
| Day 1 | 2026-05-14, Thu | no | — | no-nightlife line | n/a |
| Day 2 | 2026-05-15, Fri | no | — | no-nightlife line | n/a |
| Day 3 | 2026-05-16, Sat | yes | Alex — "watch a sunset from a rooftop" (anchor); Robin — same (wish); weekend | 1 entry + 1 alternative | covered |
| Day 4 | 2026-05-17, Sun | no | departure | no-nightlife line | n/a |

- **Applicable nights:** 1 of 4
- **Verdicts:** 1 covered · 0 declined · 0 gap · 0 contradiction · 3 n/a
- **Gate basis:** both profile-filing travellers were read for the desire limb; both are
  present on all four days. Sam filed no profile, so contributes no desire to the gate.
- **Nightlife list read:** full menu.
- Robin's *hear live fado* is carried as [W2] rather than as a gap: the night it would
  fall on is covered, and an uncovered nice-to-have on a covered night is a coverage
  reading, not a gap.

---

## Price Flags

**Not exercised.** This fixture records no prices beyond the two-axis tier labels the
alternatives rule needs, so there is no listed price to age.

---

## Travel Restrictions & Advisories

**Not exercised.** The origin and destination are placeholders and the dates are
illustrative, so there is no real jurisdiction pair to check. On a real trip this
section carries current entry requirements against each traveller's nationality — which
is the one use the `Passport:` field in `travelers/<traveler>.md` exists for, and why
that field records a country and an expiry month and never a number.

---

## Local Happenings During Travel Dates

**Not exercised.** Illustrative dates against a placeholder destination yield no
calendar to read.

---

## Hub Agent Remediation Instructions

> Prioritized action list for the hub agent's remediation pass.

1. No Critical findings — no remediation pass is required for this itinerary.
2. [W1] Hold the Serralves timed entry before Fri May 15, then move `EV-b47e` to
   `locked` in `outputs/event-status.md` and recompute that row's derived cell.
3. [W2] Accept as recorded risk, per the recommended default in
   `outputs/final-itinerary.md` § *OPEN DECISIONS*.

---

## Validation Metadata

- **Validated:** carried in frontmatter as `generated`; not restated here.
- **Itinerary version audited:** v2.
- **Items confirmed clean:** 9 checks passed; 8 declared not exercised with their
  reason; 0 Critical.
- **Items requiring human verification:** the eight not-exercised checks above. Each is
  blocked on an input this fixture declines to carry by design — external links, hours,
  prices, real bookings, a real destination — and none of them is blocked on a judgement
  a validator could have made from what is here.

---

## What this report does not cover

The prose of any artifact. This validator audits the plan; the schema gate audits
frontmatter. Neither reads narrative body content, and a green from either says nothing
about the other. **Neither reads this report's own checks-run table either** — the
number of checks a report claims to have run is asserted here and enforced nowhere, so
a check silently dropped from the table is invisible to CI. That is why the not-exercised
rows are carried rather than omitted: an omitted row and a run row are indistinguishable
to every automated reader, and only a present row that says *not exercised* is
distinguishable to a human one.
