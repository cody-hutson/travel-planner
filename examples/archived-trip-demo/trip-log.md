---
artifact: trip-log.md
schema-version: 1
trip: archived-trip-demo
writer: operator
lifecycle: accumulate-append
provenance: human
publish: internal
---

# Trip Log — Bruges 2025

> **Illustrative, sanitized example. Not a real trip.**

## Session 2025-10-13 (Mon)

**Topics:** Concluding the trip.

**Decisions:**
- The trip is over. Ran `/trip-decommission archive`: the site was taken offline, the
  `**Lifecycle:**` marker was written to `trip-context.md`, and this entry closes the
  record — in that order, which is the order the verb declares load-bearing.

**Next steps:** None. The trip is concluded.

## Session 2026-02-04 (Wed) — a referenced person record changed, and nothing here moved

**Topics:** per-4f1c edited the durable person record this trip references.

**Decisions:**
- **None taken, and that is the entry.** Discovery ran over the trips referencing that
  record and named this one **`ARCHIVED — not signalled`**. No update signal was written
  to `outputs/traveler-model.md`, no artifact of this trip was regenerated, and no byte
  of the trip changed. The model still holds the composition as it stood when the trip
  was archived.
- Recorded here because **an absence has to be stated rather than inferred from
  silence.** A reader who found no signal and no log entry could not tell a trip that
  was correctly frozen from a run that never looked at it.

**Open questions:** None. `/trip-decommission reopen` would return this trip to the
ordinary refresh population, and its next pass would compose the current values.

## Session 2026-04-22 (Wed) — an erasure reached this archived trip

**Topics:** Three people asked to be erased. All three had travelled on this trip.

**Decisions:**
- **The erasure reached this trip, and the freeze did not stand in its way.** Erasure is
  a redaction rather than a derivation, so it was never inside what the freeze forbids:
  `CLAUDE.md` § *Archived trips — what the freeze binds* states the exception in terms.
  Each subject's identifying values were **substituted** wherever this trip held them —
  the `## Group` roster cell, the constraint `Applies to:` lines, the traveller file and
  its stem, the derived model's entry heading, and this log. **Nothing was regenerated.**
- **The marker was not flipped.** The trip did not reopen, was not re-concluded, and
  gained no second closing entry. Substituting into an archived trip needs none of that.
- **The composition date on `outputs/traveler-model.md` did not move**, because a
  substitution is not a rebuild.
- Three subjects, one per model-entry class: per-4f1c (first-party, profile filed),
  per-9a3e (operator-provided needs, no profile), per-b70d (operator-provided **and**
  third-party, no roster row and no file anywhere). All three took the same single act.

**Open questions:** None. The receipt was total over the reach table and every row
carried an outcome.
