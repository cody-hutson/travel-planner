# Architecture Decision Records

This directory holds travel-planner's **architecture decision records** (ADRs) — short
documents that capture a significant, cross-cutting design decision: its context, the
options weighed, the decision, and the consequences.

## Convention

- **File name:** `ADR-NNN-kebab-title.md` — zero-padded 3-digit number, assigned
  monotonically. Numbers are never reused or renumbered.
- **Sections:** Status · Context · Decision drivers · Options considered · Decision ·
  Consequences · References. A `Follow-on build slices` section is conventional where the
  decision opens downstream work. This list is the expected spine, not a closed set — a
  record may carry further sections, and carrying one is not a divergence to be recorded.
- **Status lifecycle:** `Proposed` → `Accepted` → `Superseded`. An Accepted ADR is
  immutable **as to its decisions** — to change a decision, author a new ADR and mark the
  old one `Superseded by ADR-MMM` rather than editing the original.
- **Amendment — correcting an Accepted ADR without changing a decision.** An Accepted ADR
  **is** edited in place to correct a claim it got wrong, narrow a scope or coverage
  statement, or repair a citation whose target has moved. None of those is a change of
  decision, and none needs a new ADR. The amendment travels with the document, in either of
  the two forms already in use here: named in the `Status:` line — `amended <N> times`, then
  a `**First/Second/… amendment**` paragraph, as `ADR-008` does — or written as a dated
  `**Amendment (YYYY-MM-DD, Day) — …**` paragraph in the section it corrects, as `ADR-007`
  does. Say what was corrected and why, and **correct the claim in place rather than
  softening it**. What an amendment may never do is reverse, narrow or re-open a *decision*:
  that is the supersession path above.
- **When to write one:** for decisions that are cross-cutting or hard to reverse — roster
  or pipeline changes, the secret/publish model, cross-agent contracts. One-line fixes and
  ordinary feature slices do not need an ADR.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-001](ADR-001-nightlife-agent.md) | Dedicated nightlife agent — placement, boundary, coverage | Accepted |
| [ADR-002](ADR-002-living-site-refresh.md) | Living-site refresh — secret model, client-side ambient data, 0-plaintext-leak | Accepted |
| [ADR-003](ADR-003-group-coordination.md) | Group coordination — change representation, approval workflow, notification, privacy | Accepted |
| [ADR-004](ADR-004-contact-emergency-privacy.md) | Traveler contact & emergency info — privacy-handling model | Accepted |
| [ADR-005](ADR-005-location-invariant.md) | Location invariant — every itinerary event carries a standard, validator-gated map link | Accepted |
| [ADR-006](ADR-006-third-party-data-capture.md) | Third-party data capture — consent and attribution for party members without a profile | Accepted |
| [ADR-007](ADR-007-command-entry-point.md) | Command entry point — surface shape, privilege boundary, and taxonomy ownership | Accepted |
| [ADR-008](ADR-008-publish-content-guard.md) | Publish-path content guard — a value-keyed predicate on the plaintext limb | Accepted |
| [ADR-009](ADR-009-data-architecture.md) | Data architecture — entity identity, serialization, publishability, topology, schema evolution | Accepted |
