# Architecture Decision Records

This directory holds travel-planner's **architecture decision records** (ADRs) — short
documents that capture a significant, cross-cutting design decision: its context, the
options weighed, the decision, and the consequences.

## Convention

- **File name:** `ADR-NNN-kebab-title.md` — zero-padded 3-digit number, assigned
  monotonically. Numbers are never reused or renumbered.
- **Sections:** Status · Context · Decision drivers · Options considered · Decision · Consequences.
- **Status lifecycle:** `Proposed` → `Accepted` → `Superseded`. An Accepted ADR is
  immutable — to change a decision, author a new ADR and mark the old one
  `Superseded by ADR-MMM` rather than editing the original.
- **When to write one:** for decisions that are cross-cutting or hard to reverse — roster
  or pipeline changes, the secret/publish model, cross-agent contracts. One-line fixes and
  ordinary feature slices do not need an ADR.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-001](ADR-001-nightlife-agent.md) | Dedicated nightlife agent — placement, boundary, coverage | Accepted |
