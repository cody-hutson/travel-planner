# Decision-record coverage map

Before proposing a capability, a reader needs to know whether the engine has already decided
something about it, and in which record. This map answers that without reading every record: it
lists each capability the target declares, the records that bind it, and the capabilities no record
binds, and it names which specification documents cite the records that bind their subject.

The index in [`README.md`](README.md) is the live register of records, graded on every run. This map
is a measurement: every binding, figure and verdict below was taken at `e743113`, the commit `main`
stood at on 2026-10-02, and is re-derived by the method in the last section rather than maintained by
hand. A record added after that commit is found through the index, in its subsystem's group.

## What a capability domain is

**The list comes from the target's own tracker.** A capability domain is an issue labelled
`type: epic`, the label the target describes as "Large capability spanning many work items". One
earlier capability, the traveller-satisfaction engine, carries the older `epic` label instead and is
included. The epic is the unit because it is the only place the target names a capability as one.
Each domain is named from its epic's title, restated as the capability where the title states the gap.

**What shipped outside an epic is placed, not dropped.** A milestone none of whose cards is a sub-issue
of an epic is placed by its strongest evidence, tagged where it is listed: **E1**, an epic's own body
names it, a group of milestones it is one of, or the record that was its one deliverable; **E2**, its
own description names the epic or milestone whose capability it continues, follows or supersedes, or
another milestone's description names it so; **E3**, only its title or description resembles an epic's capability;
**E4**, nothing names or resembles another, so it is a domain of its own, named by its title. An earlier
class wins, and a mention as a dependency or a coordination note places nothing. A release whose own
description says it carries earlier releases' residuals ships no capability of its own and takes no row.

**A record binds a domain in one of three ways.**

- **Decided for it.** The record's `Driving work` field — required on every record and graded by group
  HD of `scripts/test-adr-conformance.sh` — names the domain's epic, or, naming none, its first card
  or milestone resolves there: a card by its parent epic, else by its milestone.
- **Bound by a rule.** For a domain no record was decided for, a record whose `## Decision` section
  states a rule that capability must follow binds it, and the sub-section stating the rule is named:
  a rule that says what must, may not or only may happen to a deliverable the domain's own statement —
  its epic's title and desired outcome, or its milestone's outcome — names.
- **Kind-wide.** Where every record that binds such a domain is one of the records below, whose scope
  is every capability of its kind, the domain reads **kind-wide**, and they are named in its row. One of
  them binds a domain whose own statement names a deliverable of its kind — an artifact class, a
  command, a count asserted in the corpus, or an assertion in a guard suite.

A domain bound none of these ways is **unbound**.

**The records below state a rule for every capability in their scope**, and are listed here once
rather than in every row they reach:

| Record | Its scope |
|---|---|
| [ADR-009](ADR-009-data-architecture.md) | the data contract of every artifact class |
| [ADR-007](ADR-007-command-entry-point.md) | every command — its surface shape, its privilege boundary, and who owns the taxonomy |
| [ADR-013](ADR-013-count-assertion-basis.md) | every count asserted in the corpus |
| [ADR-019](ADR-019-discriminating-evidence-rule.md) | every assertion in the guard suites |

## The domains, by subsystem

The subsystems are the groups the index uses.

### The decision tier and the repository's own rules

| Capability domain | Declared by the target as | Decided for it | Bound by a rule in | Coverage |
|---|---|---|---|---|
| Self-descriptions stay true of the engine | epic #1498; milestones *Corpus & process hygiene* (E1), *Corpus hygiene fast-follows* (E1), *Self-descriptions true of the engine* (E3), *Prompt and fixture agreement* (E3) | [ADR-013](ADR-013-count-assertion-basis.md) | — | decided |
| A control grades the population at risk | epic #1027; milestone *Privacy control integrity* (E3) | [ADR-019](ADR-019-discriminating-evidence-rule.md) | — | decided |
| Governing prose has an executable assertion | epic #825 | — | [ADR-015](ADR-015-durable-field-validity-horizon.md) § *Decision* 4 — the membership arm's declared expectation | rule |
| The repository's CI and release machinery is graded | epic #1497; milestone *Release and publish mechanics integrity* (E3) | — | [ADR-019](ADR-019-discriminating-evidence-rule.md) | **kind-wide** |
| A surface's cost is a stated property | epic #1169 | — | [ADR-013](ADR-013-count-assertion-basis.md), [ADR-019](ADR-019-discriminating-evidence-rule.md) | **kind-wide** |
| The decision tier states its own rules | epic #1499 | — | [ADR-029](ADR-029-group-approval-return-and-threshold.md) § *7* — the partial-supersession form; [ADR-010](ADR-010-per-traveler-approval-collection.md) § *8* — when a supersession takes effect | rule |

### Data architecture

| Capability domain | Declared by the target as | Decided for it | Bound by a rule in | Coverage |
|---|---|---|---|---|
| Engine-wide data architecture | epic #273 | [ADR-009](ADR-009-data-architecture.md) | — | decided |

### Commands, installation and the trip lifecycle

| Capability domain | Declared by the target as | Decided for it | Bound by a rule in | Coverage |
|---|---|---|---|---|
| Command entry point | epic #252; milestone *Command verb discoverability* (E2) | [ADR-007](ADR-007-command-entry-point.md) | — | decided |
| Guided entry to the commands | epic #607 | — | [ADR-007](ADR-007-command-entry-point.md) § *1. Surface shape*, in its amendment of 2026-09-18; [ADR-019](ADR-019-discriminating-evidence-rule.md) | **kind-wide** |
| The trip engine is one skill | epic #1501 | — | [ADR-007](ADR-007-command-entry-point.md) § *2. The privilege boundary*; [ADR-021](ADR-021-installable-capability.md) § *1* | rule |
| The engine is an installable capability | milestones *Trip engine ships as an installable capability* (E4), *Trip commands outside the repo* (E2) | [ADR-021](ADR-021-installable-capability.md) | — | decided |
| First-run experience | milestone *First-run experience* (E4) | — | [ADR-035](ADR-035-site-transitions-and-refresh.md) § *1* — `list` stays read-only and never gates | rule |
| Trip closeout | milestone *Trip closeout* (E4) | — | [ADR-025](ADR-025-engagement-model-over-time.md) § *3* — the lifecycle boundary; [ADR-027](ADR-027-post-trip-preference-memory.md) § *1. Outcome retention* | rule |

### Planning — research, the itinerary and its cost

| Capability domain | Declared by the target as | Decided for it | Bound by a rule in | Coverage |
|---|---|---|---|---|
| The traveller-satisfaction engine | epic #11 | — | [ADR-027](ADR-027-post-trip-preference-memory.md) § *1*; [ADR-006](ADR-006-third-party-data-capture.md) § *Constraints*; [ADR-012](ADR-012-people-library.md) § *6b*; [ADR-005](ADR-005-location-invariant.md) § *1*; [ADR-009](ADR-009-data-architecture.md) § *1* and § *3* | rule |
| Satisfaction metric refinements | epic #68; milestone *Satisfaction fast-follows* (E2) | — | [ADR-028](ADR-028-derived-planning-day-block-owners.md) § *2. The presence class*; [ADR-027](ADR-027-post-trip-preference-memory.md) § *1* | rule |
| Destination ideation | milestone *Destination ideation* (E4) | — | [ADR-030](ADR-030-what-the-private-site-may-show.md) § *5*; [ADR-027](ADR-027-post-trip-preference-memory.md) § *3. The Dislikes field* | rule |
| The nightlife agent | epic #59 | [ADR-001](ADR-001-nightlife-agent.md) | — | decided |
| The short-horizon replan protocol | epic #61 | — | [ADR-028](ADR-028-derived-planning-day-block-owners.md) § *1* — the trip window its signal reads | rule |
| Multi-origin and per-traveller arrival | epic #74 | — | [ADR-028](ADR-028-derived-planning-day-block-owners.md) § *2. The presence class* | rule |
| The pre-departure preparation layer | epic #90 | — | [ADR-006](ADR-006-third-party-data-capture.md) § *Identity*, whose consequence § *Q4* states; [ADR-012](ADR-012-people-library.md) § *5* | rule |
| Per-traveller cost estimation | epic #91 | [ADR-011](ADR-011-per-traveler-cost-estimation.md), [ADR-018](ADR-018-cost-estimation-method.md) | — | decided |
| The derived planning-day blocks | epic #1500; milestone *The derived blocks get an owner* (E1) | [ADR-028](ADR-028-derived-planning-day-block-owners.md) | — | decided |

### The published site and the publish path

| Capability domain | Declared by the target as | Decided for it | Bound by a rule in | Coverage |
|---|---|---|---|---|
| Faithful site rendering | epic #67 | [ADR-005](ADR-005-location-invariant.md) | — | decided |
| The living site | epic #60 | [ADR-002](ADR-002-living-site-refresh.md) | — | decided |
| The published site serves every phase | epic #1241 | [ADR-030](ADR-030-what-the-private-site-may-show.md) through [ADR-038](ADR-038-contact-emergency-group-visibility.md), each of them | — | decided |
| The site keeps one design system | epic #1502 | — | [ADR-033](ADR-033-site-section-ceiling.md) § *1. The section-growth ceiling* | rule |
| The publish path | epic #1612; milestones *Private-by-default trip sites* (E3), *Publish-flow privacy & lifecycle* (E2), *Publish-path content guard* (E3) | [ADR-008](ADR-008-publish-content-guard.md) | — | decided |

### Group coordination and approval

| Capability domain | Declared by the target as | Decided for it | Bound by a rule in | Coverage |
|---|---|---|---|---|
| Group approval for plan changes | epic #77 | [ADR-003](ADR-003-group-coordination.md), [ADR-010](ADR-010-per-traveler-approval-collection.md) | — | decided |
| Group approval and messaging | epic #1297 | [ADR-029](ADR-029-group-approval-return-and-threshold.md) | — | decided |

### The traveller journey

| Capability domain | Declared by the target as | Decided for it | Bound by a rule in | Coverage |
|---|---|---|---|---|
| The traveller journey, from ideation through archive | milestone *The traveller journey: the founding decision* (E4) | [ADR-025](ADR-025-engagement-model-over-time.md), [ADR-026](ADR-026-channel-architecture.md) | — | decided |

This is the one domain the tracker groups above the epic. Its initiative holds the living site, the
site that serves every phase, the reusable interviewer, the trip memory, and group approval and
messaging; [ADR-025](ADR-025-engagement-model-over-time.md) decides time across them and
[ADR-026](ADR-026-channel-architecture.md) decides reach.

### People and groups across trips, and what trips remember

| Capability domain | Declared by the target as | Decided for it | Bound by a rule in | Coverage |
|---|---|---|---|---|
| The reusable people library | epic #527 | [ADR-012](ADR-012-people-library.md), [ADR-014](ADR-014-cross-trip-consent-refusal.md), [ADR-015](ADR-015-durable-field-validity-horizon.md), [ADR-016](ADR-016-reusable-groups.md), [ADR-017](ADR-017-derived-trip-history.md) | — | decided |
| Trips remember how they went | epic #1197 | [ADR-027](ADR-027-post-trip-preference-memory.md) | — | decided |

### Travellers, intake and the interview

| Capability domain | Declared by the target as | Decided for it | Bound by a rule in | Coverage |
|---|---|---|---|---|
| Self-guiding traveller intake | epic #69; milestone *Intake form: corrective* (E3) | [ADR-004](ADR-004-contact-emergency-privacy.md), [ADR-006](ADR-006-third-party-data-capture.md) | — | decided |
| The reusable interviewer | epic #1205 | [ADR-022](ADR-022-interview-session-model.md), [ADR-023](ADR-023-interviewer-authored-home-and-form-contract.md), [ADR-024](ADR-024-form-contract-writer-boundary.md), [ADR-039](ADR-039-interview-conduct-bundled-with-the-verb.md), [ADR-040](ADR-040-transcript-only-return-and-save.md) | — | decided |
| Traveller data holds to its stated rules | epic #1496 | — | [ADR-006](ADR-006-third-party-data-capture.md) § *Identity*; [ADR-014](ADR-014-cross-trip-consent-refusal.md) § *1*; [ADR-016](ADR-016-reusable-groups.md) § *5. Erasure reach* | rule |

## Domains only a kind-wide record binds, and their disposition

A domain nothing was decided for, and that only a kind-wide record binds or none binds, carries a
disposition. A record is warranted where the domain carries a decision that is cross-cutting or hard
to reverse — the test [`README.md`](README.md) § *Convention* states under *When to write one*. Where it
carries none, the domain is out of scope for the decision tier, and the reason names where its design is
held. No domain read unbound at `e743113`.

| Capability domain | Disposition | Reason |
|---|---|---|
| A surface's cost is a stated property | **a record is warranted** | whether an accepted record may grow, and where settled design belongs, binds every later record and specification document. It is decided in the release that added this map |
| Guided entry to the commands | out of scope | where inference may enter, and that a surface which only proposes is admitted, is decided in [ADR-007](ADR-007-command-entry-point.md) § *1*'s amendment of 2026-09-18; a record is warranted only for a decision it leaves open |
| The repository's CI and release machinery is graded | out of scope | the release procedure is `CONTRIBUTING.md` § *Cutting a release*, the required checks are listed in `SECURITY.md`, and what makes a gate trustworthy is [ADR-019](ADR-019-discriminating-evidence-rule.md) |

**Step 3's search, as run at `e743113`**, for each domain that reads kind-wide and each whose rule it
found; the hits are the records whose `## Decision` section names one of the domain's declared files.

| Capability domain | Records hit (of 39) | Coverage, after reading each hit |
|---|---|---|
| Guided entry to the commands | 16 | kind-wide |
| The repository's CI and release machinery is graded | 6 | kind-wide |
| A surface's cost is a stated property | 20 | kind-wide |
| Governing prose has an executable assertion | 20 | rule |
| The decision tier states its own rules | 6 | rule |
| Satisfaction metric refinements | 18 | rule |
| The short-horizon replan protocol | 18 | rule |
| First-run experience | 8 | rule |

At `e743113` the search fires on this population: over the artifacts `reference/data-model.md`
declares, the satisfaction engine, which nothing was decided for, hits 20 with its rules among them. It
finds ADR-011 and ADR-018 for the cost domain, and none for the near-miss `traveller-model.md`, which no
tracked file spells.

### Two names this map was asked to settle

The first measurement of this tier, a vocabulary scan taken at `dc00c8e`, named two capability domains
it found no record for. Neither is unbound under the definition above.

| Name | Where it falls | Disposition |
|---|---|---|
| learnings / retrospectives | the domain *Trips remember how they went* — a trip's outcomes survive it, and the next plan for the same person starts from them | **covered.** [ADR-027](ADR-027-post-trip-preference-memory.md) was decided for it and accepted on 2026-09-24, after the scan, and [ADR-025](ADR-025-engagement-model-over-time.md) decides what crosses from one trip to the next. Neither record uses the scan's words, which is why it could not see them |
| proactive improvement | no domain: the target declares no epic, milestone, command verb or artifact class for it. The nearest thing it holds is the per-trip `engine-learnings.md` file, which [`reference/data-architecture.md`](../data-architecture.md) § *1.2* declares out of the artifact model and routes to its own intake | **out of scope for the decision tier.** A record becomes warranted if that intake brings the file into the artifact model with a writer, as the records that added the cost estimate, the person record and the group record each did |

## Which specification documents are decision-anchored

A specification document is **decision-anchored** when it cites at least one record that binds the
domain it specifies — decided for it, by a rule, or kind-wide — and **not anchored** when it cites none
of them or its domain has no record to cite. The domain a document specifies is the capability its own
title and opening paragraph name. A citation is a distinct `ADR-NNN` token in the document's text,
measured at `e743113`.

| Specification document | The domain it specifies | Records it cites | Records that bind that domain | Verdict |
|---|---|---|---|---|
| [`reference/data-architecture.md`](../data-architecture.md) | engine-wide data architecture | 10 — ADR-005, ADR-006, ADR-007, ADR-008, ADR-009, ADR-011, ADR-012, ADR-013, ADR-016, ADR-018 | ADR-009, decided for it | **decision-anchored** |
| [`reference/data-model.md`](../data-model.md) | the satisfaction layer of the traveller-satisfaction engine | 6 — ADR-005, ADR-006, ADR-009, ADR-012, ADR-022, ADR-024 | by a rule: ADR-005, ADR-006, ADR-009, ADR-012, ADR-027 — and ADR-009 § *1* decides about this document itself | **decision-anchored** |
| [`reference/site-layout-spec.md`](../site-layout-spec.md) | the one design system the site keeps, which its title names | 3 — ADR-002, ADR-003, ADR-008 | by a rule: ADR-033 | **not anchored**: it cites no record that binds its subject. Read as specifying every capability one of its sections serves, it is anchored: its coordination-notice component cites ADR-003 and ADR-002 as rules it follows |
| [`SKILL.md`](../../SKILL.md) at the engine root | guided entry to the commands | 1 — ADR-007 | kind-wide: ADR-007 | **decision-anchored**; not anchored on a reading that counts no kind-wide record |

The data tier is anchored. In the design tier the satisfaction layer's document is anchored and the
site's is not on the reading this map states, so whether the design tier is anchored rests on the site's
document alone. Where settled design belongs is decided outside this map.

## Re-deriving this map

Each step reads the target as it stands, and names the control that shows it read something.

1. **The domains.** List the issues labelled `type: epic` and the one with the older `epic` label, every
   milestone, and each epic's sub-issues with their milestones; place each milestone outside the epics
   by its strongest evidence class. Control: each epic's sub-issue count equals the total its own
   summary reports.
2. **Decided for.** Resolve each record's `Driving work` field — the epic it names, else its first card
   or milestone — to a domain. Control: every record resolves to one domain.
3. **Bound by a rule.** For each domain nothing was decided for, look for a rule on a deliverable its own
   statement names. Where that finds none but a kind-wide one, search: read every record whose
   `## Decision` section names a file named by its epic's body or by the descriptions of the milestones
   that are its alone — less directories, `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md` and
   `CHANGELOG.md` — or an artifact a specification document titled for it declares. Control: the search
   fires on a domain whose rule is known, not on a near-miss.
4. **Anchoring.** Extract the distinct three-digit `ADR-NNN` tokens from each specification document.
   Control: the same extraction at `dc00c8e` returns 11, 4, 3 and 1, in the table's order.
