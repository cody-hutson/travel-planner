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
  old one `Superseded by ADR-MMM` rather than editing the original; where only one decision,
  or part of one, changes, the partial form below applies.
- **Amendment — correcting an Accepted ADR without changing a decision.** An Accepted ADR
  **is** edited in place to correct a claim it got wrong, narrow a scope or coverage
  statement, or repair a citation whose target has moved. None of those is a change of
  decision, and none needs a new ADR. The amendment travels with the document: its account takes
  the consolidated-decision form below, and an account written before that form stands where it
  was written — named in the `Status:` line, `amended <N> times` and then a
  `**First/Second/… amendment**` paragraph, as `ADR-008` does, or a dated
  `**Amendment (YYYY-MM-DD, Day) — …**` paragraph in the section it corrects, as `ADR-007` does.
  Say what was corrected and why, and **correct the claim in place rather than softening it**.
  What an amendment may never do is reverse, narrow or re-open a *decision*: that is the
  supersession path above.
- **Superseding one decision, or part of one.** Where a later record supersedes one decision of
  an Accepted ADR, or part of one, and the rest of that ADR stands, the earlier ADR is **not**
  marked `Superseded`: its `Status:` value and its index cell stay `Accepted`, because the record
  is still in force. Three things carry the change instead. The superseding record names, in its
  own Decision section, the record and the decision it supersedes and states that the rest
  stands. The earlier ADR's `Status:` line records the supersession — the decision, the
  superseding record and the date — as an amendment that **records** a decision taken elsewhere
  and takes none itself, the one kind of amendment that may concern a decision. And the
  superseded text is retained as decided, never rewritten, with an inline marker at it pointing
  forward. The supersession is recorded when it takes effect and not before: for a rule
  implemented in code, that is the change that ships the replacement. `ADR-009`'s eighth
  amendment is the first instance of this form.
- **Consolidated-decision form — an amended ADR reads at its current state.** This form is decided
  by [the record on what an Accepted ADR may gain](ADR-042-accepted-record-growth.md), and every
  amendment of an Accepted ADR made after this bullet was added takes it. The amendment's account
  is an entry in a closing `## Amendment history` section, placed after `References`; no new
  account is written into the `Status:` line or into a section, and the corrected claim stands
  corrected in the sentence that makes it. An entry opens `**Amendment (YYYY-MM-DD, Day) — …**`,
  or `**<Ordinal> amendment (YYYY-MM-DD, Day) — …**` where the amendment is cited by an ordinal.
  It names the section it corrected, says what was corrected and why, and quotes the wording it
  replaced where that wording still stands, in the ADR or in an earlier account. Entries stand
  oldest first, and entries of one date in the order the amendments were made. The `Status:` line
  carries the lifecycle value with its date, and the record of each partial supersession. An
  account written before this form stays where it stands, in an ADR amended in either earlier form
  or in both, until a consolidation moves it; an ADR changed with no account takes no entry for
  that history. Consolidating is optional and nothing schedules it: one change moves every earlier
  account of an ADR to an entry and rewrites its sections to what those amendments left in force,
  and it changes no decision. The partial form above governs a partial supersession in every ADR,
  consolidated or not, wherever it and this form differ, and the text a supersession retains stays
  where it stands, with its marker. No consolidation, relocation or reduction of an ADR removes or
  rewords a rejected alternative or the reason given for rejecting it, wherever in the ADR it
  stands.
- **What an amendment may add.** The bound is on what a span states, never on its size: a span an
  amendment adds or rewrites is outside it when it states something a reader must follow that the
  ADR did not already say — a rule, an obligation, a permitted case, an account of a mechanism the
  ADR did not give. A new decision is a new ADR. A correction replaces a false statement with a
  true one, and corrects only a claim the ADR already made; where the true form is settled design
  — a table, grammar, enumeration, procedure, measured boundary or ledger — the correction is one
  sentence naming where that shape is stated, the specification document for its subject under
  `reference/` or the suite group that pins it, and the shape is never restated in the ADR. Inside
  the bound by construction: an amendment's own account; a consolidation's moves; a relocation's
  removal of settled design and its pointer to the home; a rejected alternative recorded with its
  reason; and a removal that reverses, narrows or re-opens no decision and removes no rejected
  alternative. A machine-readable declaration of a decision the ADR already states is admitted when
  it restates exactly what the decision states and adds nothing a reader must follow; a declaration
  that adds a member is a new decision. Settled design belongs in the specification document for
  its subject, which names the ADR that decided it, as `reference/data-architecture.md` § 12 does
  for its own. The amendment rule above, the consolidated-decision form and this bound apply to an
  ADR from its ratification on `main`; a change made before then, while the ADR is `Proposed` or
  accepted only on a release's branch, is revision and not amendment. The practice here is two
  steps: an ADR lands `Proposed`, and a later change on `main` sets `Accepted` with its date in the
  `Status:` line and the index row. An ADR that a release lands `Accepted` is ratified when that
  release merges.
- **When to write one:** for decisions that are cross-cutting or hard to reverse — roster
  or pipeline changes, the secret/publish model, cross-agent contracts. One-line fixes and
  ordinary feature slices do not need an ADR.

## Number declarations

A number is spent when it is published. The convention above forbids reuse and renumbering, so
a record withdrawn after its number was assigned does not give the number back — the sequence
keeps a gap where it stood. That leaves two states a reader cannot tell apart by looking: a gap
somebody decided to carry, and a number that was simply lost.

The fence below is what tells them apart. Each row declares a number the sequence carries as a
deliberate gap, and `scripts/test-corpus-hygiene.sh` group **D** grades the numbering against
it. A number inside the span that no record file occupies and no row here declares is a
finding; so is a row whose number turns out to be occupied, to sit outside the span, or not to
be a number at all. That second direction is what keeps a declaration from outliving the gap it
excepts and becoming a standing exemption for whatever next takes that number.

The same group grades what nothing in this repository previously asserted: that a number is
carried by at most one record file and at most one index row, and that the index below and the
directory around it name the same records in both directions.

Two columns, both required, whitespace-separated — the same shape as the count-assertion
declaration in `reference/data-architecture.md`. A line whose first non-blank character is `#`
is a comment; a blank line is ignored. The left column is the number and the right a single
reason token; a row carrying only a number is not a declaration, and its number still reads
undeclared. Why a particular gap exists belongs in the record that withdrew it, not here.

```adr-number-declaration
# number  reason
020       superseded-record-never-merged
```

`ADR-020` is the only number declared today. It was assigned to the record `ADR-021`
supersedes, on a branch that has since been swept; `ADR-021` § *Costs and residual risks*
carries the account.

## Index

Each record has exactly one row below, in the group for the subsystem it was decided for — the
capability its `Driving work` field names. The [coverage map](coverage-map.md) names, as measured at
`e743113`, the capability each record then present was decided for, the records that otherwise bind
a capability nothing was decided for, the capabilities no record binds, and which specification
documents cite the records that bind them. A new record's row goes at the foot of its group's table,
so each group stays in number order.

### The decision tier and the repository's own rules

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-013](ADR-013-count-assertion-basis.md) | Count assertions carry a re-derivable basis — the four admitted basis forms, and the declared residual | Accepted |
| [ADR-019](ADR-019-discriminating-evidence-rule.md) | The Discriminating-Evidence Rule — an assertion's PASS must require evidence its subject could only have produced by running | Accepted |
| [ADR-042](ADR-042-accepted-record-growth.md) | Accepted records after acceptance — what an amendment may add, the consolidated-decision form, and where settled design belongs | Accepted |
| [ADR-043](ADR-043-required-check-census-parser.md) | The required-check census reads a parsed document — PyYAML on the runner, a marker read from the comment layer, and a refusal wherever it cannot vouch | Proposed |

### Data architecture

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-009](ADR-009-data-architecture.md) | Data architecture — entity identity, serialization, publishability, topology, schema evolution | Accepted |

### Commands, installation and the trip lifecycle

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-007](ADR-007-command-entry-point.md) | Command entry point — surface shape, privilege boundary, and taxonomy ownership | Accepted |
| [ADR-021](ADR-021-installable-capability.md) | The trip engine is an installable capability, not a folder you open | Accepted |

### Planning — research, the itinerary and its cost

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-001](ADR-001-nightlife-agent.md) | Dedicated nightlife agent — placement, boundary, coverage | Accepted |
| [ADR-011](ADR-011-per-traveler-cost-estimation.md) | Per-traveler cost estimation — a new in-model class, and the one field the entry marker admits | Accepted |
| [ADR-018](ADR-018-cost-estimation-method.md) | Cost estimation method — the commitment axis, the C13 read edge, and ADR-011's three deferred questions | Accepted |
| [ADR-028](ADR-028-derived-planning-day-block-owners.md) | Owners for the derived planning-day blocks — the trip window to the verb that records its inputs, and each traveller's window to a presence file the reconciler rebuilds | Accepted |

### The published site and the publish path

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-002](ADR-002-living-site-refresh.md) | Living-site refresh — secret model, client-side ambient data, 0-plaintext-leak | Accepted |
| [ADR-005](ADR-005-location-invariant.md) | Location invariant — every itinerary event carries a standard, validator-gated map link | Accepted |
| [ADR-008](ADR-008-publish-content-guard.md) | Publish-path content guard — a value-keyed predicate on the plaintext limb | Accepted |
| [ADR-030](ADR-030-what-the-private-site-may-show.md) | What the private trip site may show — the coordination test, the share mark, and nothing personal on a public page | Accepted |
| [ADR-031](ADR-031-site-phase-model.md) | The site's phase model — the resolved state drives its shape through one render table, and what each state's build renders | Accepted |
| [ADR-032](ADR-032-site-round-trip-contract.md) | The site's round-trip contract across its rendered artifacts — two grains, one render table, and a walk in three passes | Accepted |
| [ADR-033](ADR-033-site-section-ceiling.md) | The site's section-growth ceiling — four tests over declared tables, and what earns a section | Accepted |
| [ADR-034](ADR-034-site-build-admission.md) | The site build's admission of the pre-plan states — one requirement row, a declared stop, the page's file name, and the pre-plan classes | Accepted |
| [ADR-035](ADR-035-site-transitions-and-refresh.md) | The site's transitions — replace, never accumulate; what a traveller was shown; and the refresh obligation | Accepted |
| [ADR-036](ADR-036-published-artifact-model-row.md) | The published artifact takes no in-model row — `ADR-026` Finding 1 declined, in terms, and routed | Accepted |
| [ADR-037](ADR-037-group-snapshot.md) | The group snapshot — what travellers share with the group before a plan, whose it is, who writes it, and where it shows | Accepted |
| [ADR-038](ADR-038-contact-emergency-group-visibility.md) | Contact and emergency information on the private site — what the group sees, the emergency contact as a third party, and the carrier | Accepted |

### Group coordination and approval

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-003](ADR-003-group-coordination.md) | Group coordination — change representation, approval workflow, notification, privacy | Accepted |
| [ADR-010](ADR-010-per-traveler-approval-collection.md) | Per-traveler approval collection — transport over server, the attestation ceiling, and the unnamed channel | Accepted |
| [ADR-029](ADR-029-group-approval-return-and-threshold.md) | Group approval — the inbound return as an operator-mediated crossing, approvals the organizer records against a declared threshold, and one decision of ADR-003 superseded in part | Accepted |

### The traveller journey

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-025](ADR-025-engagement-model-over-time.md) | The engagement model over time — the axis the engine already computes, what carries across a boundary, and identity continuity | Accepted |
| [ADR-026](ADR-026-channel-architecture.md) | The channel architecture — what a channel is, the channel-set, what each may carry, and the crossing model | Accepted |

### People and groups across trips, and what trips remember

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-012](ADR-012-people-library.md) | People library — cross-trip person identity, merge semantics, erasure reach, and reference discovery | Accepted |
| [ADR-014](ADR-014-cross-trip-consent-refusal.md) | Cross-trip consent for a party member — the mechanism space, and why the refusal closes rather than defers | Accepted |
| [ADR-015](ADR-015-durable-field-validity-horizon.md) | The durable-field validity horizon — a trip-relative predicate, a declared axis, and no fifth write | Accepted |
| [ADR-016](ADR-016-reusable-groups.md) | Reusable groups — a second cross-trip store, a one-directional membership edge, and an expansion that leaves no residue | Accepted |
| [ADR-017](ADR-017-derived-trip-history.md) | Derived trip history — a resolution rather than a record, a match the operator makes, and a suggestion that is never written | Accepted |
| [ADR-027](ADR-027-post-trip-preference-memory.md) | Post-trip preference memory — outcomes resolved where they were measured, a group view over the trips the operator confirms, one durable dislike field, and no group slot | Accepted |

### Travellers, intake and the interview

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-004](ADR-004-contact-emergency-privacy.md) | Traveler contact & emergency info — privacy-handling model | Accepted |
| [ADR-006](ADR-006-third-party-data-capture.md) | Third-party data capture — consent and attribution for party members without a profile | Accepted |
| [ADR-022](ADR-022-interview-session-model.md) | The interview session model — derived resumption, a three-valued read of the unanswered class, and one write per answer | Accepted |
| [ADR-023](ADR-023-interviewer-authored-home-and-form-contract.md) | The interviewer's authored home and the form contract — a declared fence, the restatement homes retired, and what the next form costs | Accepted |
| [ADR-024](ADR-024-form-contract-writer-boundary.md) | The form contract's writer boundary — the owned region as the unit, a key of region and condition, and an exclusion that executes rather than amends | Accepted |
| [ADR-039](ADR-039-interview-conduct-bundled-with-the-verb.md) | The interview's shared conduct is bundled with the interviewer verb — a file beside its command file, superseding ADR-023 D1.1 in part | Accepted |
| [ADR-040](ADR-040-transcript-only-return-and-save.md) | What a transcript-only channel returns, and who saves it — superseding ADR-022 D6.1's tier-T row in part | Accepted |
| [ADR-041](ADR-041-third-party-roster-standing.md) | A third-party member's roster standing — no `## Group` row, and one unnamed place in `Total travelers` | Accepted |
